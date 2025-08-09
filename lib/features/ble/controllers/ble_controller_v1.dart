import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../../../data/models/device/battery_details.dart';
import '../../../core/utils/extensions/list/list_extensions.dart';

import '../../../main.dart';
import '../../../data/models/ble/ble_device.dart';
import '../../../data/models/measurement/measured_data.dart';
import '../../../data/models/measurement/sensor_details.dart';
import '../../../features/settings/controllers/app_settings.dart';
import 'ble_controller.dart';

class BleControllerV1 implements BleControllerForProtocol {
  // Singleton
  BleControllerV1._();

  static final BleControllerV1 _instance = BleControllerV1._();

  factory BleControllerV1() => _instance;

  final Uuid serviceId = Uuid.parse("0931b4b5-2917-4a8d-9e72-23103c09ac29");
  final Uuid _bleConfigId = Uuid.parse("8d473240-13cb-1776-b1f2-823711b3ffff");
  final Uuid _bleDataId = Uuid.parse("4b439140-73cb-4776-b1f2-8f3711b3bb4f");
  final Uuid _ldCfgId = Uuid.parse("51dc5a1c-46e0-4524-ab31-c165483ebab4");
  // Removed unused field: _ldCmdId
  final Uuid _ldInfoId = Uuid.parse("13fa8751-57af-4597-a0bb-b202f6111ae6");

  final _ble = FlutterReactiveBle();

  @override
  Future<void> getDeviceDetails(BleDevice device) async {
    List<int> config = await _ble.readCharacteristic(QualifiedCharacteristic(
      serviceId: serviceId,
      characteristicId: _bleConfigId,
      deviceId: device.bleId!,
    ));
    List<int> deviceInfo = await _ble.readCharacteristic(QualifiedCharacteristic(
      serviceId: serviceId,
      characteristicId: _ldInfoId,
      deviceId: device.bleId!,
    ));
    int startOfFloat = deviceInfo.indexOf(4);
    int firmwareVersionMajor = deviceInfo[startOfFloat + 1];
    int firmwareVersionMinor = deviceInfo[startOfFloat + 2];
    device.firmwareVersion = FirmwareVersion(firmwareVersionMajor, firmwareVersionMinor);
    // Parse list of available devices
    int numberOfDevices = config[4];
    int offset = 5;
    List<SensorDetails> sensorDetails = [];
    try {
      for (int i = 0; i < numberOfDevices; i++) {
        logger.d('Parsing device $i');
        int deviceType = config[offset];
        int numberOfDimensions = config[offset + 1];
        switch (deviceType) {
          case 1:
            // TODO this only works while no sensors but Sen5x send their details
            List<int> tupleStarts = deviceInfo.allIndicesOf((e) => e == 6);
            List<int> sensorIdPart = deviceInfo.sublist(tupleStarts[1], tupleStarts[2]);
            sensorDetails.add(SensorDetails(
              LDSensor.sen5x,
              serialNumber:
                  utf8.decode(sensorIdPart.sublist(sensorIdPart.lastIndexWhere((e) => e == 1) + 2)),
              firmwareVersion:
                  '${deviceInfo[tupleStarts[3] - 2]}.${deviceInfo[tupleStarts[3] - 1]}',
              hardwareVersion:
                  '${deviceInfo[tupleStarts[4] - 2]}.${deviceInfo[tupleStarts[4] - 1]}',
              protocolVersion:
                  '${deviceInfo[deviceInfo.length - 2]}.${deviceInfo[deviceInfo.length - 1]}',
            ));
            break;
          default:
            sensorDetails.add(SensorDetails(LDSensor.fromId(deviceType)));
            break;
        }
        offset += 2 + numberOfDimensions;
      }
    } catch (_) {
      logger.e('Failed to parse sensor details');
    }
    device.availableSensors = sensorDetails;
    device.batteryDetails = BatteryDetails(status: BatteryStatus.unsupported);
  }

  @override
  Future<List<SensorDataPoint>> readSensorValues(BleDevice device) async {
    String deviceId = device.bleId!;
    logger.d('Reading raw data');
    List<int> rawData = await _ble.readCharacteristic(QualifiedCharacteristic(
      serviceId: serviceId,
      characteristicId: _bleDataId,
      deviceId: deviceId,
    ));
    logger.d('Read raw data');
    return _SensorDataParser(rawData).parse();
  }

  @override
  Future<bool> sendAirStationConfig(BleDevice device, List<int> bytes) async {
    if (device.state != BleDeviceState.connected) {
      return false;
    }
    QualifiedCharacteristic qc = QualifiedCharacteristic(
      serviceId: serviceId,
      characteristicId: _ldCfgId,
      deviceId: device.bleId!,
    );
    try {
      await _ble.writeCharacteristicWithResponse(qc, value: bytes);
      return true;
    } catch (_, trace) {
      logger.d(trace);
      return false;
    }
  }

  @override
  Future<List<int>?> readAirStationConfiguration(BleDevice device) async {
    if (device.state != BleDeviceState.connected) {
      return null;
    }
    return await _ble.readCharacteristic(QualifiedCharacteristic(
      serviceId: serviceId,
      characteristicId: _ldCfgId,
      deviceId: device.bleId!,
    ));
  }
}

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
