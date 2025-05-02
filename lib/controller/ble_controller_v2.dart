import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/controller/ble_controller.dart';
import 'package:luftdaten.at/model/device_error.dart';
import 'package:luftdaten.at/model/sensor_details.dart';

import '../main.dart';
import '../model/battery_details.dart';
import '../model/ble_device.dart';
import '../model/measured_data.dart';
import 'app_settings.dart';

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
    logger.d('Raw device details: $rawDeviceDetails');
    // Set firmware version
    device.firmwareVersion = FirmwareVersion(
      rawDeviceDetails[1],
      rawDeviceDetails[2],
      rawDeviceDetails[3],
    );
    // Next bytes contain device model and name, not relevant in this case.
    // Potential sensor errors are stored in bytes 9+
    int numberOfConfiguredSensors = rawDeviceDetails[9];
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
    List<int> rawSensorDetails =
        await _ble.readCharacteristic(_characteristic(_sensorDetailsId, device));
    List<List<int>> sensorDetailsParts = rawSensorDetails.split(0xff);
    device.availableSensors = [];
    for (int i = 0; i < sensorDetailsParts.length / 2; i++) {
      List<int> sensorSpec = sensorDetailsParts[i * 2];
      List<int> sensorDetails = sensorDetailsParts[i * 2 + 1];
      LDSensor model = LDSensor.fromId(sensorSpec[0]);
      // The remainder of sensorSpec includes which values a sensor measures, which we already know
      if (model == LDSensor.sen5x) {
        // Currently, only Sen5x comes with specific sensor details
        device.availableSensors!.add(SensorDetails(
          model,
          firmwareVersion: '${sensorDetails[0]}.${sensorDetails[1]}',
          hardwareVersion: '${sensorDetails[2]}.${sensorDetails[3]}',
          protocolVersion: '${sensorDetails[4]}.${sensorDetails[5]}',
          serialNumber: utf8.decode(sensorDetails.sublist(6)),
        ));
      } else if(model == LDSensor.sht4x) {
        device.availableSensors!.add(SensorDetails(
          model,
          serialNumber: hex.encode(sensorDetails),
        ));
      } else {
        device.availableSensors!.add(SensorDetails(model));
      }
    }
    // Get battery status. This does not trigger a new battery readout!
    // Ideally, turn BLE device off & on again before connecting to get up-to-date battery status
    List<int> rawBatteryData =
        await _ble.readCharacteristic(_characteristic(_deviceStatusId, device));
    device.batteryDetails = BatteryDetails.fromBytes(rawBatteryData.sublist(0, 3));
    logger.d('Battery status: ${device.batteryDetails}');
    device.notify();
  }

  @override
  /// Note: this can throw an error if the device is no longer connected
  Future<List<SensorDataPoint>> readSensorValues(BleDevice device) async {
    // In protocol version 2, we first need to instruct the device to take a new measurement
    // Measure battery status every 10th iteration
    DateTime? batteryLastMeasured = device.batteryDetails?.timestamp;
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
    await Future.delayed(
        const Duration(seconds: 2)); // Is 1s a reasonable wait time? Needs to be tested
    // Read out battery percentage, even if we haven't requested a new one
    // This ensures we get new values quickly
    List<int> rawBatteryData =
        await _ble.readCharacteristic(_characteristic(_deviceStatusId, device));
    device.batteryDetails = BatteryDetails.fromBytes(rawBatteryData.sublist(0, 3));
    logger.d('Battery status: ${device.batteryDetails}');
    if(measureBattery) logger.d('(Newly requested)');
    List<int> rawSensorData = await _ble.readCharacteristic(_characteristic(_sensorDataId, device));

    final jsonString = utf8.decode(rawSensorData);
    List<dynamic> j = json.decode(jsonString);

    Map<String, dynamic> data = j[0];
    rawSensorData = List<int>.from(j[1]);

    return _SensorDataParser(rawSensorData).parse();
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
    while (true) {
      logger.d('Device starts at: $offset');
      logger.d('Number of data entries: ${raw[offset + 1]}');
      int numBytes = 2 + raw[offset + 1] * 3;
      logger.d('Total bytes for this device: $numBytes');
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
