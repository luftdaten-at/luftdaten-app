import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';

/// Builds debug-only mock BLE devices for simulator/emulator testing.
class MockBleDevices {
  MockBleDevices._();

  static BleDevice buildMockDevice(
    LDDeviceModel model, {
    required Iterable<String> existingBleNames,
  }) {
    final suffix = _nextSuffix(existingBleNames);
    final mac = suffix.toRadixString(16).padLeft(12, '0').toUpperCase();
    final bleName = 'Luftdaten.at-$mac';
    final displayName = switch (model) {
      LDDeviceModel.station => 'Air Station $suffix',
      LDDeviceModel.aRound => 'Air aRound $suffix',
      LDDeviceModel.badge => 'Air Badge $suffix',
      _ => '${model.name} $suffix',
    };

    return BleDevice(
      model: model,
      bleName: bleName,
      bleMacAddress: mac,
      deviceOriginalDisplayName: displayName,
      autoReconnect: model.portable,
      isMock: true,
      bleId: 'mock:$bleName',
    );
  }

  static int _nextSuffix(Iterable<String> existingBleNames) {
    var max = 0;
    for (final name in existingBleNames) {
      final match = RegExp(r'Luftdaten\.at-([0-9A-Fa-f]{12})').firstMatch(name);
      if (match == null) continue;
      final n = int.tryParse(match.group(1)!, radix: 16) ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }

  static bool canUseMockBle(BleDevice device) =>
      AppSettings.mockBleActive && device.isMock;
}
