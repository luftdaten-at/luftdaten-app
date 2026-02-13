import 'package:luftdaten.at/model/ble_device.dart';

/// Shared test constants to avoid duplication.
class TestConstants {
  TestConstants._();

  /// Creates a minimal BleDevice for tests (use BleDevice.unknown() when possible).
  static BleDevice get unknownDevice => BleDevice.unknown();
}
