import 'dart:math';

import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

/// Populates plausible GATT-like fields on a mock [BleDevice].
class MockBleProfile {
  MockBleProfile._();

  static final _rng = Random();

  static void apply(BleDevice device) {
    if (!MockBleDevices.canUseMockBle(device)) return;

    device.bleId ??= 'mock:${device.bleName}';
    device.protocolVersion = 2;
    device.firmwareVersion = const FirmwareVersion(1, 0, 0);
    device.availableSensors = [
      SensorDetails(
        LDSensor.sen5x,
        serialNumber: 'MOCK-SEN5X',
        firmwareVersion: '1.0.0',
      ),
    ];
    final pct = 72 + (_rng.nextDouble() * 8);
    device.batteryDetails = BatteryDetails(
      status: BatteryStatus.discharging,
      percentage: pct,
      voltage: 3.9,
      timestamp: DateTime.now(),
    );
    if (device.model == LDDeviceModel.station) {
      device.operationalNotices = const [
        BleDeviceNotice(id: 'config_incomplete', severity: BleNoticeSeverity.warning),
      ];
    } else {
      device.operationalNotices = [];
    }
  }

  static void refreshStatus(BleDevice device) {
    if (!MockBleDevices.canUseMockBle(device)) return;
    final prev = device.batteryDetails?.percentage ?? 78;
    final next = (prev + (_rng.nextDouble() * 2 - 1)).clamp(20.0, 95.0);
    device.batteryDetails = BatteryDetails(
      status: BatteryStatus.discharging,
      percentage: next,
      voltage: 3.7 + next / 100 * 0.5,
      timestamp: DateTime.now(),
    );
  }
}
