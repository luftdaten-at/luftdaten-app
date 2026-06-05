import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';

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
    await GetStorage.init('settings');
    GetStorage('devices').remove('devices');
    AppSettings.I.mockBleDevicesEnabled = true;
  });

  group('MockBleDevices', () {
    test('buildMockDevice uses MOCK mac and isMock', () {
      final device = MockBleDevices.buildMockDevice(
        LDDeviceModel.aRound,
        existingBleNames: const [],
      );
      expect(device.isMock, isTrue);
      expect(device.bleMacAddress, hasLength(12));
      expect(int.tryParse(device.bleMacAddress, radix: 16), isNotNull);
      expect(device.bleName, contains('Luftdaten.at-'));
      expect(device.bleId, 'mock:${device.bleName}');
    });

    test('addMockDevice reuses existing mock of same model', () {
      final manager = DeviceManager();
      final first = manager.addMockDevice(LDDeviceModel.station);
      final second = manager.addMockDevice(LDDeviceModel.station);
      expect(first, isNotNull);
      expect(second, same(first));
      expect(manager.devices.length, 1);
    });

    test('addMockPresetBundle adds two devices', () {
      final manager = DeviceManager();
      manager.addMockPresetBundle();
      expect(manager.devices.length, 2);
      expect(manager.devices.every((d) => d.isMock), isTrue);
    });
  });
}
