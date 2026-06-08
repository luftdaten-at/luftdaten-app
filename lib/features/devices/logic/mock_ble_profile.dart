import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';

/// Populates mock [BleDevice] fields for widget tests (without full BLE connect).
class MockBleProfile {
  MockBleProfile._();

  static void apply(BleDevice device) {
    if (!MockBleDevices.canUseMockBle(device)) return;
    MockBleGatt.initForDevice(device);
    device.protocolVersion = 2;
  }

  static void refreshStatus(BleDevice device) {
    if (!MockBleDevices.canUseMockBle(device)) return;
    MockBleGatt.stateFor(device).refreshBattery();
  }
}
