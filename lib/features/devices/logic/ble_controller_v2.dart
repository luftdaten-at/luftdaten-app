import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/flutter_reactive_ble_transport.dart';
import 'package:luftdaten.at/features/devices/data/device_error.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';

import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/logic/ble_json_parser.dart';
import '../data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/sd_ble_export.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/devices/logic/device_api_key_ble_sync.dart';
import 'package:luftdaten.at/features/devices/logic/device_api_key_resolver.dart';

class BleControllerV2 implements BleControllerForProtocol {
  BleControllerV2._(this._transport);

  static final BleControllerV2 _instance =
      BleControllerV2._(FlutterReactiveBleTransport.instance);

  factory BleControllerV2({BleGattTransport? transport}) {
    if (transport == null) return _instance;
    return BleControllerV2._(transport);
  }

  final BleGattTransport _transport;

  static const int _bleCmdSdLogExport = 0x08;
  static const Duration _sdBleIoDelay = Duration(milliseconds: 220);

  @override
  Future<void> getDeviceDetails(BleDevice device) async {
    List<int> rawDeviceDetails = await _transport.readCharacteristic(
      deviceId: device.bleId!,
      serviceId: BleGattUuids.service,
      characteristicId: BleGattUuids.deviceInfo,
    );
    logger.d('getDeviceDetails: rawDeviceDetails len=${rawDeviceDetails.length}, hex=${rawDeviceDetails.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}, raw=$rawDeviceDetails');
    bool usedJsonFormat = false;
    if (rawDeviceDetails.isNotEmpty && rawDeviceDetails[0] == 0x7B) {
      try {
        final jsonStr = utf8.decode(rawDeviceDetails);
        final info = json.decode(jsonStr) as Map<String, dynamic>;
        await DeviceApiKeyBleSync.applyFromBleMetadata(
          device,
          info,
          logSource: 'device_info_json',
        );
        final station = info['station'];
        final deviceBlock = info['device'];
        device.firmwareVersion =
            BleJsonParser.parseFirmwareFromStation(
              station is Map ? Map<String, dynamic>.from(station) : null,
            ) ??
            BleJsonParser.parseFirmwareFromDevice(
              deviceBlock is Map ? Map<String, dynamic>.from(deviceBlock) : null,
            ) ??
            const FirmwareVersion(0, 0, 0);
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
            await DeviceApiKeyBleSync.applyKey(
              device,
              utf8.decode(apiKeyBytes),
              logSource: 'device_info_binary',
            );
          } catch (_) {}
        }
      }
    }
    if (device.model == LDDeviceModel.station) {
      try {
        final tlvBytes = await readAirStationConfiguration(device);
        if (tlvBytes != null && tlvBytes.isNotEmpty) {
          await DeviceApiKeyBleSync.applyFromAirStationConfigBytes(device, tlvBytes);
        }
      } catch (e) {
        logger.d('getDeviceDetails: air_station_configuration read failed: $e');
      }
    }
    await DeviceApiKeyResolver.hydrateDeviceFromSecureStorage(device);
    if (device.apiKey != null && device.apiKey!.isNotEmpty) {
      logger.d('getDeviceDetails: apiKey loaded (hydrated from secure storage or BLE)');
    }
    try {
      List<int> rawSensorDetails = await _transport.readCharacteristic(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.sensorInfo,
      );
      List<List<int>> sensorDetailsParts = rawSensorDetails.split(0xff);
      device.availableSensors = [];
      for (int i = 0; i < sensorDetailsParts.length / 2; i++) {
        List<int> sensorSpec = sensorDetailsParts[i * 2];
        List<int> sensorDetails = sensorDetailsParts[i * 2 + 1];
        if (sensorSpec.isEmpty) continue;
        LDSensor model = LDSensor.fromId(sensorSpec[0]);
        if ((model == LDSensor.sen5x || model == LDSensor.sen66) && sensorDetails.length >= 6) {
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
    List<int> rawBatteryData = await _transport.readCharacteristic(
      deviceId: device.bleId!,
      serviceId: BleGattUuids.service,
      characteristicId: BleGattUuids.deviceStatus,
    );
    logger.d('getDeviceDetails: rawBatteryData len=${rawBatteryData.length}, hex=${rawBatteryData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}, raw=$rawBatteryData');
    applyDeviceStatusBytes(device, rawBatteryData);
    logger.d(
      'Device status: battery=${device.batteryDetails}, '
      'notices=${device.operationalNotices.map((n) => n.id).join(",")}',
    );
    device.notify();
  }

  @override
  Future<void> refreshDeviceStatus(BleDevice device) async {
    if (device.state != BleDeviceState.connected || device.bleId == null) return;
    try {
      final raw = await _transport.readCharacteristic(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.deviceStatus,
      );
      applyDeviceStatusBytes(device, raw);
      logger.d(
        'refreshDeviceStatus: notices=${device.operationalNotices.map((n) => n.id).join(",")}',
      );
    } catch (e) {
      logger.d('refreshDeviceStatus failed: $e');
    }
  }

  Future<List<int>> _readWithRetry({
    required String deviceId,
    required Uuid characteristicId,
  }) async {
    try {
      return await _transport.readCharacteristic(
        deviceId: deviceId,
        serviceId: BleGattUuids.service,
        characteristicId: characteristicId,
      );
    } catch (e) {
      logger.d('BLE read failed ($e), retrying after delay');
      await Future.delayed(const Duration(milliseconds: 500));
      return await _transport.readCharacteristic(
        deviceId: deviceId,
        serviceId: BleGattUuids.service,
        characteristicId: characteristicId,
      );
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
    await _transport.writeCharacteristicWithoutResponse(
      deviceId: device.bleId!,
      serviceId: BleGattUuids.service,
      characteristicId: BleGattUuids.command,
      value: [measureBattery ? 0x02 : 0x01],
    );
    logger.d('Wrote to command characteristic');
    await Future.delayed(const Duration(milliseconds: 2500));
    List<int> rawBatteryData = await _readWithRetry(
      deviceId: device.bleId!,
      characteristicId: BleGattUuids.deviceStatus,
    );
    applyDeviceStatusBytes(device, rawBatteryData);
    logger.d(
      'Battery/status: ${device.batteryDetails}, '
      'notices=${device.operationalNotices.map((n) => n.id).join(",")}',
    );
    if(measureBattery) logger.d('(Newly requested)');
    List<int> rawSensorData = await _readWithRetry(
      deviceId: device.bleId!,
      characteristicId: BleGattUuids.sensorValues,
    );
    if (rawSensorData.length < 2) {
      logger.d('BLE sensor data too short (len=${rawSensorData.length}), retrying');
      await Future.delayed(const Duration(milliseconds: 1000));
      rawSensorData = await _readWithRetry(
        deviceId: device.bleId!,
        characteristicId: BleGattUuids.sensorValues,
      );
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
      await DeviceApiKeyBleSync.applyFromBleMetadata(
        device,
        data,
        logSource: 'sensor_values_json',
      );
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
    if (device.state != BleDeviceState.connected) {
      return false;
    }
    try {
      final chunks =
          AirStationBleHomeAssistantDefaults.chunkSetAirStationConfiguration(bytes);
      for (var i = 0; i < chunks.length; i++) {
        await _transport.writeCharacteristicWithoutResponse(
          deviceId: device.bleId!,
          serviceId: BleGattUuids.service,
          characteristicId: BleGattUuids.command,
          value: chunks[i],
        );
        logger.d(
            'sendAirStationConfig fragment ${i + 1}/${chunks.length}, len=${chunks[i].length}');
        if (i + 1 < chunks.length) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
      return true;
    } catch (e) {
      logger.d(e);
      return false;
    }
  }

  @override
  Future<List<int>?> readAirStationConfiguration(BleDevice device) async {
    logger.d('Reading AirStation Configuration Start');

    List<int> rawData = await _transport.readCharacteristic(
      deviceId: device.bleId!,
      serviceId: BleGattUuids.service,
      characteristicId: BleGattUuids.airStationConfiguration,
    );

    logger.d('Reading AirStation Configuration Done');

    return rawData;
  }

  /// Idle READ on `sd_log_export_characteristic`: `flags` bit0 means JSONL exists (non-empty).
  Future<SdBleExportIdleInfo?> peekSdBleExportIdle(BleDevice device) async {
    if (device.state != BleDeviceState.connected || device.bleId == null) {
      return null;
    }
    try {
      final raw = await _transport.readCharacteristic(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.sdLogExport,
      );
      final frame = SdBleExportFrame.parse(raw);
      if (!frame.isIdle) return null;
      return SdBleExportIdleInfo(sdLogNonEmpty: frame.idleSdLogNonEmpty);
    } catch (e, st) {
      logger.d('peekSdBleExportIdle failed: $e $st');
      return null;
    }
  }

  /// Streams SD JSONL via BLE command `0x08` (wifiless Air Station only).
  Future<SdBleImportResult> importSdJsonlLines(
    BleDevice device, {
    void Function(int lineIndex)? onProgress,
  }) async {
    if (device.model != LDDeviceModel.station) {
      return SdBleImportResult.error('Nur für Air Station verfügbar.');
    }
    if (device.state != BleDeviceState.connected || device.bleId == null) {
      return SdBleImportResult.error('Bluetooth nicht verbunden.');
    }

    Future<void> delayIo() => Future<void>.delayed(_sdBleIoDelay);

    try {
      await _transport.writeCharacteristicWithoutResponse(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.command,
        value: <int>[_bleCmdSdLogExport, 0],
      );
      await delayIo();
    } catch (e, st) {
      logger.d('SD export START write failed: $e $st');
      return SdBleImportResult.error('SD-Export konnte nicht gestartet werden.');
    }

    final out = <Map<String, dynamic>>[];
    final buf = StringBuffer();
    var lineIndex = 0;
    const maxFrames = 200000;

    for (var n = 0; n < maxFrames; n++) {
      try {
        await _transport.writeCharacteristicWithoutResponse(
          deviceId: device.bleId!,
          serviceId: BleGattUuids.service,
          characteristicId: BleGattUuids.command,
          value: <int>[_bleCmdSdLogExport, 1],
        );
        await delayIo();

        List<int> raw;
        try {
          raw = await _readWithRetry(
            deviceId: device.bleId!,
            characteristicId: BleGattUuids.sdLogExport,
          );
        } catch (e, st) {
          logger.d('SD export READ failed: $e $st');
          return SdBleImportResult.error('SD-Export: Lesen fehlgeschlagen.');
        }

        final frame = SdBleExportFrame.parse(raw);

        switch (frame.status) {
          case SdBleExportConstants.statusErr:
            return SdBleImportResult.error(
              SdBleImportResult.mapErrorSubcode(frame.flags & 0xff),
              subcode: frame.flags & 0xff,
            );
          case SdBleExportConstants.statusEof:
            return SdBleImportResult.success(out);
          case SdBleExportConstants.statusPartial:
          case SdBleExportConstants.statusEol:
            if (frame.payload.isNotEmpty) {
              buf.write(utf8.decode(frame.payload));
            }
            if (frame.status == SdBleExportConstants.statusEol) {
              final line = buf.toString();
              buf.clear();
              final decoded = tryDecodeJsonlObject(line);
              if (decoded != null) {
                out.add(decoded);
                lineIndex++;
                onProgress?.call(lineIndex);
              }
            }
            break;
          case SdBleExportConstants.statusIdle:
            // After EOF, firmware may return idle; treat as done if buffer empty.
            if (buf.isEmpty) {
              return SdBleImportResult.success(out);
            }
            break;
          default:
            logger.d('SD export: unexpected status ${frame.status}');
            break;
        }
      } catch (e, st) {
        logger.d('SD export loop error: $e $st');
        return SdBleImportResult.error('SD-Export abgebrochen: $e');
      }
    }

    return SdBleImportResult.error('SD-Export: zu viele Pakete (Abbruch).');
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
