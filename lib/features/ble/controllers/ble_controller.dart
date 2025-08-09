import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_controller_v1.dart';
import '../../../data/models/ble/ble_device.dart';

import '../../../main.dart';
// Removed unused import: measured_data.dart
import 'ble_controller_v2.dart';

class BleController {
  final Uuid serviceId = Uuid.parse("0931b4b5-2917-4a8d-9e72-23103c09ac29");
  final Uuid _bleConfigId = Uuid.parse("8d473240-13cb-1776-b1f2-823711b3ffff");

  final _ble = FlutterReactiveBle();

  Stream<ConnectionStateUpdate> connectTo(BleDevice device) {
    logger.d('Connecting to device ${device.bleId}');
    return _ble.connectToDevice(
      id: device.bleId!,
      connectionTimeout: const Duration(milliseconds: 5000),
    );
  }

  Future<int> getProtocolVersion(BleDevice device) async {
    if(device.protocolVersion != null) return device.protocolVersion!;
    logger.d('Getting protocol version from device ${device.bleId}');
    List<int> config = await _ble.readCharacteristic(QualifiedCharacteristic(
      serviceId: serviceId,
      characteristicId: _bleConfigId,
      deviceId: device.bleId!,
    ));
    int protocolVersion = config[0];
    logger.d('Protocol version is $protocolVersion');
    if(protocolVersion > 2) {
      logger.e('Incompatible protocol (version $protocolVersion, expected =1 or =2)');
      throw IncompatibleFirmwareException(protocolVersion);
    }
    device.protocolVersion = protocolVersion;
    return protocolVersion;
  }

  Future<void> getDeviceDetailsAndCheckProtocol(BleDevice device) async {
    await getProtocolVersion(device);
    return BleControllerForProtocol(device.protocolVersion!).getDeviceDetails(device);
  }

  Future<List<dynamic>> readSensorValues(BleDevice device) async {
    await getProtocolVersion(device);
    return BleControllerForProtocol(device.protocolVersion!).readSensorValues(device);
  }

  Future<bool> sendAirStationConfig(BleDevice device, List<int> bytes) async {
    await getProtocolVersion(device);
    return BleControllerForProtocol(device.protocolVersion!).sendAirStationConfig(device, bytes);
  }

  Future<List<int>?> readAirStationConfiguration(BleDevice device) async {
    await getProtocolVersion(device);
    return BleControllerForProtocol(device.protocolVersion!).readAirStationConfiguration(device);
  }
}

class IncompatibleFirmwareException implements Exception {
  final int protocolVersion;

  const IncompatibleFirmwareException(this.protocolVersion);
}

extension Sum on List<int> {
  int get sum {
    int count = 0;
    for (int i in this) {
      count += i;
    }
    return count;
  }
}

abstract class BleControllerForProtocol {
  factory BleControllerForProtocol(int protocolVersion) {
    switch (protocolVersion) {
      case 1:
        return BleControllerV1();
      case 2:
        return BleControllerV2();
      default:
        throw IncompatibleFirmwareException(protocolVersion);
    }
  }

  Future<void> getDeviceDetails(BleDevice device);

  Future<List<dynamic>> readSensorValues(BleDevice device);

  Future<bool> sendAirStationConfig(BleDevice device, List<int> bytes);

  Future<List<int>?> readAirStationConfiguration(BleDevice device);
}
