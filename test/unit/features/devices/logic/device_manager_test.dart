import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') return '/tmp';
      if (methodCall.method == 'getTemporaryDirectory') return '/tmp';
      return null;
    });
  });

  setUp(() async {
    await GetStorage.init('devices');
    GetStorage('devices').remove('devices');
  });

  group('DeviceManager', () {
    test('addDevice adds to list and saves', () {
      final manager = DeviceManager();
      final device = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-X-1',
        bleMacAddress: 'AABBCCDDEEFF',
        deviceOriginalDisplayName: 'Luftdaten.at-X-1',
      );
      manager.addDevice(device);
      expect(manager.devices, [device]);
    });

    test('deleteDevice removes and saves', () {
      final manager = DeviceManager();
      final device = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-X-1',
        bleMacAddress: 'AABBCCDDEEFF',
        deviceOriginalDisplayName: 'Luftdaten.at-X-1',
      );
      manager.addDevice(device);
      manager.deleteDevice(device);
      expect(manager.devices, isEmpty);
    });

    test('addDeviceByCode parses valid QR code', () {
      final manager = DeviceManager();
      // Format: displayName;bleName;modelId. bleMacAddress = bleName.split('-')[1]
      final code = 'Luftdaten.at-AABBCCDDEEFF-1;Luftdaten.at-AABBCCDDEEFF-1;1';
      final device = manager.addDeviceByCode(code);
      expect(device, isNotNull);
      expect(device!.bleName, 'Luftdaten.at-AABBCCDDEEFF-1');
      expect(device.deviceOriginalDisplayName, 'Luftdaten.at-AABBCCDDEEFF-1');
      expect(device.model, LDDeviceModel.aRound);
      expect(device.bleMacAddress, 'AABBCCDDEEFF');
    });

    test('addDeviceByCode returns existing device when bleName matches', () {
      final manager = DeviceManager();
      final code = 'Luftdaten.at-AABBCCDDEEFF-1;Luftdaten.at-AABBCCDDEEFF-1;1';
      final first = manager.addDeviceByCode(code);
      final second = manager.addDeviceByCode(code);
      expect(first, second);
      expect(manager.devices.length, 1);
    });

    test('addDeviceByCode returns null for invalid code', () {
      final manager = DeviceManager();
      expect(manager.addDeviceByCode(null), isNull);
      expect(manager.addDeviceByCode('invalid'), isNull);
      expect(manager.addDeviceByCode('too;few'), isNull);
    });
  });
}
