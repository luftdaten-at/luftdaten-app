import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geolocator/geolocator.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller_v1.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller_v2.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';
import 'package:luftdaten.at/features/devices/logic/sd_ble_export.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_devices.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_telemetry.dart';

import 'package:luftdaten.at/core/core.dart';

class BleController {
  final Uuid serviceId = Uuid.parse("0931b4b5-2917-4a8d-9e72-23103c09ac29");
  final Uuid _bleConfigId = Uuid.parse("8d473240-13cb-1776-b1f2-823711b3ffff");

  final _ble = FlutterReactiveBle();

  BleControllerV2 get _mockV2 =>
      BleControllerV2(transport: MockBleGattTransport.instance);

  Stream<ConnectionStateUpdate> connectTo(BleDevice device) {
    logger.d('Connecting to device ${device.bleId}');
    // Omit servicesWithCharacteristicsToDiscover to trigger full GATT discovery on iOS.
    // Partial discovery can miss write-only characteristics (e.g. command trigger).
    return _ble.connectToDevice(
      id: device.bleId!,
      connectionTimeout: const Duration(milliseconds: 5000),
    );
  }

  Future<int> getProtocolVersion(BleDevice device) async {
    if (MockBleDevices.canUseMockBle(device)) {
      device.protocolVersion = 2;
      return 2;
    }
    if(device.protocolVersion != null) return device.protocolVersion!;
    logger.d('Getting protocol version from device ${device.bleId}');
    List<int> config = await _ble.readCharacteristic(QualifiedCharacteristic(
      serviceId: serviceId,
      characteristicId: _bleConfigId,
      deviceId: device.bleId!,
    ));
    int protocolVersion = config[0];
    // Device may send JSON (get_info with station.api.key) - first byte 0x7B = '{'
    if (protocolVersion == 0x7B) {
      logger.d('Device sends JSON format (get_info), assuming protocol 2');
      protocolVersion = 2;
    }
    logger.d('Protocol version is $protocolVersion');
    if(protocolVersion > 2) {
      logger.e('Incompatible protocol (version $protocolVersion, expected =1 or =2)');
      throw IncompatibleFirmwareException(protocolVersion);
    }
    device.protocolVersion = protocolVersion;
    return protocolVersion;
  }

  Future<void> getDeviceDetailsAndCheckProtocol(BleDevice device) async {
    if (MockBleDevices.canUseMockBle(device)) {
      MockBleGatt.initForDevice(device);
      device.protocolVersion = 2;
      await _mockV2.getDeviceDetails(device);
      return;
    }
    await getProtocolVersion(device);
    return BleControllerForProtocol(device.protocolVersion!).getDeviceDetails(device);
  }

  Future<List<dynamic>> readSensorValues(
    BleDevice device, {
    Position? position,
  }) async {
    if (MockMeasurementDevices.isLiveMeasurementDevice(device)) {
      return MockMeasurementTelemetry.readSensorValues(device, position: position);
    }
    if (MockBleDevices.canUseMockBle(device)) {
      device.protocolVersion = 2;
      return _mockV2.readSensorValues(device);
    }
    await getProtocolVersion(device);
    return BleControllerForProtocol(device.protocolVersion!).readSensorValues(device);
  }

  Future<bool> sendAirStationConfig(BleDevice device, List<int> bytes) async {
    if (MockBleDevices.canUseMockBle(device)) {
      device.protocolVersion = 2;
      return _mockV2.sendAirStationConfig(device, bytes);
    }
    await getProtocolVersion(device);
    return BleControllerForProtocol(device.protocolVersion!).sendAirStationConfig(device, bytes);
  }

  Future<List<int>?> readAirStationConfiguration(BleDevice device) async {
    if (MockBleDevices.canUseMockBle(device)) {
      device.protocolVersion = 2;
      return _mockV2.readAirStationConfiguration(device);
    }
    await getProtocolVersion(device);
    return BleControllerForProtocol(device.protocolVersion!).readAirStationConfiguration(device);
  }

  /// Idle peek: SD JSONL file on wifiless Air Station is non-empty (protocol v2 only).
  Future<SdBleExportIdleInfo?> peekSdBleExport(BleDevice device) async {
    if (MockBleDevices.canUseMockBle(device)) return null;
    await getProtocolVersion(device);
    if (device.protocolVersion != 2) return null;
    return BleControllerV2().peekSdBleExportIdle(device);
  }

  /// Re-read device details, sensors, and operational status over an existing connection.
  Future<void> refreshDeviceInfo(BleDevice device) async {
    if (device.state != BleDeviceState.connected || device.bleId == null) return;
    if (MockBleDevices.canUseMockBle(device)) {
      device.errors.clear();
      device.protocolVersion = 2;
      await _mockV2.getDeviceDetails(device);
      await _mockV2.refreshDeviceStatus(device);
      device.notify();
      return;
    }
    device.errors.clear();
    await getDeviceDetailsAndCheckProtocol(device);
    await refreshDeviceStatus(device);
    device.notify();
  }

  /// Poll `device_status` for battery and operational notices (protocol v2).
  Future<void> refreshDeviceStatus(BleDevice device) async {
    if (MockBleDevices.canUseMockBle(device)) {
      device.protocolVersion = 2;
      return _mockV2.refreshDeviceStatus(device);
    }
    await getProtocolVersion(device);
    if (device.protocolVersion != 2) return;
    return BleControllerV2().refreshDeviceStatus(device);
  }

  /// Stream SD JSONL lines over BLE (`0x08` START/NEXT); protocol v2 / Air Station only.
  Future<SdBleImportResult> importSdJsonlFromBle(
    BleDevice device, {
    void Function(int lineIndex)? onProgress,
  }) async {
    if (MockBleDevices.canUseMockBle(device)) {
      return SdBleImportResult.error('SD-Import ist für Mock-Geräte nicht verfügbar.');
    }
    await getProtocolVersion(device);
    if (device.protocolVersion != 2) {
      return SdBleImportResult.error('SD-Import benötigt Firmware-Protokoll 2.');
    }
    return BleControllerV2().importSdJsonlLines(device, onProgress: onProgress);
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

  /// Reads `device_status` (battery + operational flags). Protocol v2 only.
  Future<void> refreshDeviceStatus(BleDevice device) async {}
}
