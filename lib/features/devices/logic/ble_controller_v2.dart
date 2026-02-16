import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/data/device_error.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';

import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/logic/ble_json_parser.dart';
import '../data/battery_details.dart';
import '../data/ble_device.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';

class BleControllerV2 implements BleControllerForProtocol {
  // Singleton
  BleControllerV2._();

  static final BleControllerV2 _instance = BleControllerV2._();

  factory BleControllerV2() => _instance;

  final _ble = FlutterReactiveBle();

  // UUIDs
  final Uuid _serviceId = Uuid.parse("0931b4b5-2917-4a8d-9e72-23103c09ac29");
  final Uuid _sensorDataId = Uuid.parse("4b439140-73cb-4776-b1f2-8f3711b3bb4f");
  final Uuid _commandId = Uuid.parse("030ff8b1-1e45-4ae6-bf36-3bca4c38cdba");
  final Uuid _deviceDetailsId = Uuid.parse("8d473240-13cb-1776-b1f2-823711b3ffff");
  final Uuid _sensorDetailsId = Uuid.parse("13fa8751-57af-4597-a0bb-b202f6111ae6");
  final Uuid _deviceStatusId = Uuid.parse("77db81d9-9773-49b4-aa17-16a2f93e95f2");
  final Uuid _airStationConfigId = Uuid.parse("b47b0cdf-0ced-49a9-86a5-d78a03ea7674");

  @override
  Future<void> getDeviceDetails(BleDevice device) async {
    List<int> rawDeviceDetails =
        await _ble.readCharacteristic(_characteristic(_deviceDetailsId, device));
    logger.d('getDeviceDetails: rawDeviceDetails len=${rawDeviceDetails.length}, hex=${rawDeviceDetails.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}, raw=$rawDeviceDetails');
    bool usedJsonFormat = false;
    if (rawDeviceDetails.isNotEmpty && rawDeviceDetails[0] == 0x7B) {
      try {
        final jsonStr = utf8.decode(rawDeviceDetails);
        final info = json.decode(jsonStr) as Map<String, dynamic>;
        final apikey = BleJsonParser.parseApiKey(info);
        if (apikey != null) {
          device.apiKey = apikey;
          logger.d('getDeviceDetails: parsed apiKey from device info JSON');
        }
        final station = info['station'];
        device.firmwareVersion = BleJsonParser.parseFirmwareFromStation(
          station is Map ? Map<String, dynamic>.from(station) : null,
        ) ?? const FirmwareVersion(0, 0, 0);
        usedJsonFormat = true;
      } catch (e) {
        logger.d('getDeviceDetails: JSON parse failed: $e');
      }
    }
    if (!usedJsonFormat && rawDeviceDetails.length >= 10) {
      // Binary format: set firmware, parse sensor status, parse api_key
      device.firmwareVersion = FirmwareVersion(
        rawDeviceDetails[1],
        rawDeviceDetails[2],
        rawDeviceDetails[3],
      );
      int numberOfConfiguredSensors = rawDeviceDetails[9];
      int sensorBlockEnd = 10 + numberOfConfiguredSensors * 2;
      for (int i = 0; i < numberOfConfiguredSensors; i++) {
        LDSensor sensor = LDSensor.fromId(rawDeviceDetails[10 + i * 2]);
        int status = rawDeviceDetails[11 + i * 2];
        if (status == 0) {
          logger.d('Sensor $sensor failed to initialise');
          device.errors.add(SensorNotFoundError(sensor));
        } else {
          logger.d('Sensor $sensor successfully initialised');
        }
      }
      // Binary format may append api_key: 1 byte length + N bytes UTF-8
      if (rawDeviceDetails.length >= sensorBlockEnd + 1) {
        int apiKeyLen = rawDeviceDetails[sensorBlockEnd];
        if (apiKeyLen > 0 &&
            rawDeviceDetails.length >= sensorBlockEnd + 1 + apiKeyLen) {
          final apiKeyBytes = rawDeviceDetails.sublist(
              sensorBlockEnd + 1, sensorBlockEnd + 1 + apiKeyLen);
          try {
            device.apiKey = utf8.decode(apiKeyBytes);
            logger.d('getDeviceDetails: parsed apiKey from device info (binary)');
          } catch (_) {}
        }
      }
    }
    try {
      List<int> rawSensorDetails =
          await _ble.readCharacteristic(_characteristic(_sensorDetailsId, device));
      List<List<int>> sensorDetailsParts = rawSensorDetails.split(0xff);
      device.availableSensors = [];
      for (int i = 0; i < sensorDetailsParts.length / 2; i++) {
        List<int> sensorSpec = sensorDetailsParts[i * 2];
        List<int> sensorDetails = sensorDetailsParts[i * 2 + 1];
        if (sensorSpec.isEmpty) continue;
        LDSensor model = LDSensor.fromId(sensorSpec[0]);
        if (model == LDSensor.sen5x && sensorDetails.length >= 6) {
          device.availableSensors!.add(SensorDetails(
            model,
            firmwareVersion: '${sensorDetails[0]}.${sensorDetails[1]}',
            hardwareVersion: '${sensorDetails[2]}.${sensorDetails[3]}',
            protocolVersion: '${sensorDetails[4]}.${sensorDetails[5]}',
            serialNumber: sensorDetails.length > 6 ? utf8.decode(sensorDetails.sublist(6)) : '',
          ));
        } else if (model == LDSensor.sht4x) {
          device.availableSensors!.add(SensorDetails(
            model,
            serialNumber: hex.encode(sensorDetails),
          ));
        } else {
          device.availableSensors!.add(SensorDetails(model));
        }
      }
    } catch (e) {
      logger.d('getDeviceDetails: sensor_info read failed ($e), continuing with empty sensor list');
      device.availableSensors = [];
    }
    // Get battery status. This does not trigger a new battery readout!
    // Ideally, turn BLE device off & on again before connecting to get up-to-date battery status
    List<int> rawBatteryData =
        await _ble.readCharacteristic(_characteristic(_deviceStatusId, device));
    logger.d('getDeviceDetails: rawBatteryData len=${rawBatteryData.length}, hex=${rawBatteryData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}, raw=$rawBatteryData');
    device.batteryDetails = BatteryDetails.fromBytes(rawBatteryData.sublist(0, 3));
    logger.d('Battery status: ${device.batteryDetails}');
    device.notify();
  }

  Future<List<int>> _readWithRetry(QualifiedCharacteristic qc) async {
    try {
      return await _ble.readCharacteristic(qc);
    } catch (e) {
      logger.d('BLE read failed ($e), retrying after delay');
      await Future.delayed(const Duration(milliseconds: 500));
      return await _ble.readCharacteristic(qc);
    }
  }

  @override
  /// Note: this can throw an error if the device is no longer connected
  Future<List<dynamic>> readSensorValues(BleDevice device) async {
    /*
    retuns a tuple of (List<SensorDataPoint>: this is the old data format, Map<String, dynamic> json: the new data format)
    */
    // In protocol version 2, we first need to instruct the device to take a new measurement
    // Measure battery status every 10th iteration
    bool measureBattery = false;
    device.batteryReadoutCounter++;
    if(device.needsBatteryReadout) {
      measureBattery = true;
      device.batteryReadoutCounter = 0;
    }
    await _ble.writeCharacteristicWithoutResponse(
      _characteristic(_commandId, device),
      value: [measureBattery ? 0x02 : 0x01],
    );
    logger.d('Wrote to command characteristic');
    await Future.delayed(const Duration(milliseconds: 2500));
    List<int> rawBatteryData =
        await _readWithRetry(_characteristic(_deviceStatusId, device));
    device.batteryDetails = BatteryDetails.fromBytes(rawBatteryData.sublist(0, 3));
    logger.d('Battery status: ${device.batteryDetails}');
    if(measureBattery) logger.d('(Newly requested)');
    List<int> rawSensorData = await _readWithRetry(_characteristic(_sensorDataId, device));
    if (rawSensorData.length < 2) {
      logger.d('BLE sensor data too short (len=${rawSensorData.length}), retrying');
      await Future.delayed(const Duration(milliseconds: 1000));
      rawSensorData = await _readWithRetry(_characteristic(_sensorDataId, device));
    }

    // Debug: log first bytes to distinguish JSON (0x5B='[') vs binary format
    final firstByte = rawSensorData.isNotEmpty ? rawSensorData[0] : null;
    final format = (firstByte == 0x5B) ? 'JSON' : 'binary';
    logger.d('BLE sensor data format: $format (firstByte=0x${firstByte?.toRadixString(16) ?? 'none'}, len=${rawSensorData.length})');

    // V2 protocol: JSON array [map, rawBytes]. V1/binary fallback: raw bytes only.
    if (rawSensorData.isNotEmpty && rawSensorData[0] == 0x5B) {
      // Starts with '[' - treat as JSON
      String jsonString;
      try {
        jsonString = utf8.decode(rawSensorData);
      } on FormatException catch (e) {
        logger.d('Invalid UTF-8 from sensor data (device ${device.bleId}): $e');
        rethrow;
      }

      List<dynamic> j;
      try {
        j = json.decode(jsonString);
      } on FormatException catch (e) {
        logger.d('Invalid JSON from sensor data (device ${device.bleId}): $e');
        rethrow;
      }

      final data = j[0] as Map<String, dynamic>;
      rawSensorData = List<int>.from(j[1]);
      logger.d('BLE JSON metadata j[0]: $data');
      final apikey = BleJsonParser.parseApiKey(data);
      if (apikey != null && (device.apiKey == null || device.apiKey!.isEmpty)) {
        device.apiKey = apikey;
        logger.d('BLE: cached apiKey from sensor metadata to device');
      }
      return [_SensorDataParser(rawSensorData).parse(), data];
    }

    // Binary format (V1 or device not ready) - parse raw bytes, no JSON metadata
    logger.d('BLE using binary format: no JSON metadata, apikey not available from device');
    try {
      final dataPoints = _SensorDataParser(rawSensorData).parse();
      return [dataPoints, <String, dynamic>{}];
    } catch (e) {
      logger.d('Failed to parse binary sensor data (device ${device.bleId}): $e');
      rethrow;
    }
  }

  @override
  Future<bool> sendAirStationConfig(BleDevice device, List<int> bytes) async {
    if(device.state != BleDeviceState.connected){
      return false;
    }
    QualifiedCharacteristic qc = QualifiedCharacteristic(
      serviceId: _serviceId,
      characteristicId: _commandId,
      deviceId: device.bleId!
    );
    try {
      print("send bytes");
      print(bytes);
      await _ble.writeCharacteristicWithoutResponse(qc, value: bytes);
      print("erfolgreich");
      return true;
    } catch (e) {
      logger.d(e);
      return false;
    }
  }

  @override
  Future<List<int>?> readAirStationConfiguration(BleDevice device) async {
    logger.d('Reading AirStation Configuration Start');

    List<int> rawData = await _ble.readCharacteristic(QualifiedCharacteristic(
      serviceId: _serviceId,
      characteristicId: _airStationConfigId,
      deviceId: device.bleId!,
    ));

    logger.d('Reading AirStation Configuration Done');

    return rawData;
  }

  QualifiedCharacteristic _characteristic(Uuid characteristicId, BleDevice device) {
    return QualifiedCharacteristic(
      serviceId: _serviceId,
      characteristicId: characteristicId,
      deviceId: device.bleId!,
    );
  }
}

/// This is, for now, unchanged from V1.
class _SensorDataParser {
  final List<int> raw;

  const _SensorDataParser(this.raw);

  List<SensorDataPoint> parse() {
    int offset = 0;
    List<int> sensorOffsets = [];
    List<int> sensorDataLengths = [];
    logger.d('Raw data received: $raw');
    while (offset < raw.length) {
      if (offset + 2 > raw.length) {
        logger.d('Truncated data: need at least 2 bytes at offset $offset, have ${raw.length - offset}');
        break;
      }
      logger.d('Device starts at: $offset');
      final numEntries = raw[offset + 1];
      logger.d('Number of data entries: $numEntries');
      final numBytes = 2 + numEntries * 3;
      logger.d('Total bytes for this device: $numBytes');
      if (offset + numBytes > raw.length) {
        logger.d('Truncated device block: need $numBytes bytes, have ${raw.length - offset}');
        break;
      }
      sensorOffsets.add(offset);
      sensorDataLengths.add(numBytes);
      offset += numBytes;
      if (sensorDataLengths.sum >= raw.length) {
        logger.d('Parsed all data');
        break;
      }
    }
    List<SensorDataPoint> parsedData = [];
    for (int i = 0; i < sensorOffsets.length; i++) {
      parsedData.add(
        parseSensorData(raw.sublist(sensorOffsets[i], sensorOffsets[i] + sensorDataLengths[i])),
      );
    }
    return parsedData;
  }

  SensorDataPoint parseSensorData(List<int> sensorData) {
    Map<MeasurableQuantity, double> values = {};
    for (int i = 0; i < (sensorData.length - 2) / 3; i++) {
      values[MeasurableQuantity.fromId(sensorData[2 + i * 3])] =
          ((sensorData[2 + i * 3 + 1] << 8) | sensorData[2 + i * 3 + 2]) / 10.0;
    }
    filterUsingSettings(values);
    return SensorDataPoint(sensor: LDSensor.fromId(sensorData[0]), values: values);
  }

  void filterUsingSettings(Map<MeasurableQuantity, double> original) {
    if (!AppSettings.I.measurePM1) {
      original.remove(MeasurableQuantity.pm1);
    }
    if (!AppSettings.I.measurePM25) {
      original.remove(MeasurableQuantity.pm25);
    }
    if (!AppSettings.I.measurePM4) {
      original.remove(MeasurableQuantity.pm4);
    }
    if (!AppSettings.I.measurePM10) {
      original.remove(MeasurableQuantity.pm10);
    }
    if (!AppSettings.I.measureHumidity) {
      original.remove(MeasurableQuantity.humidity);
    }
    if (!AppSettings.I.measureTemp) {
      original.remove(MeasurableQuantity.temperature);
    }
    if (!AppSettings.I.measureVOC) {
      original.remove(MeasurableQuantity.voc);
    }
    if (!AppSettings.I.measureNOX) {
      original.remove(MeasurableQuantity.nox);
    }
    if (!AppSettings.I.measurePressure) {
      original.remove(MeasurableQuantity.pressure);
    }
    if (!AppSettings.I.measureCO2) {
      original.remove(MeasurableQuantity.co2);
    }
    if (!AppSettings.I.measureO3) {
      original.remove(MeasurableQuantity.o3);
    }
    if (!AppSettings.I.measureAQI) {
      original.remove(MeasurableQuantity.aqi);
    }
    if (!AppSettings.I.measureGasResistance) {
      original.remove(MeasurableQuantity.gasResistance);
    }
    if (!AppSettings.I.measureTotalVoc) {
      original.remove(MeasurableQuantity.totalVoc);
    }
  }
}

extension _Split on List<int> {
  List<List<int>> split(int on) {
    List<List<int>> result = [];
    List<int> current = [];
    for (int i in this) {
      if (i == on) {
        result.add(current);
        current = [];
      } else {
        current.add(i);
      }
    }
    if (current.isNotEmpty) result.add(current);
    return result;
  }
}
