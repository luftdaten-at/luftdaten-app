import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/device_api_key_resolver.dart';

BleDevice _testDevice({String? apiKey}) {
  final d = BleDevice(
    model: LDDeviceModel.aRound,
    bleName: 'Luftdaten.at Air Around 0024',
    bleMacAddress: '28372F808415',
    deviceOriginalDisplayName: 'Air Around 0024',
  );
  d.apiKey = apiKey;
  return d;
}

void main() {
  tearDown(() {
    DeviceApiKeyResolver.storedApiKeyReader = (bleName) async => null;
  });

  group('DeviceApiKeyResolver.resolve', () {
    test('prefers BLE metadata over device cache', () async {
      final device = _testDevice(apiKey: 'cached-key');
      final result = await DeviceApiKeyResolver.resolve(
        device: device,
        bleMetadata: {
          'device': {
            'api': {'key': 'ble-key'},
          },
        },
        readStored: (_) async => 'stored-key',
      );
      expect(result.key, 'ble-key');
      expect(result.source, DeviceApiKeySource.bleMetadata);
    });

    test('uses device cache when BLE has no key', () async {
      final device = _testDevice(apiKey: 'cached-key');
      final result = await DeviceApiKeyResolver.resolve(
        device: device,
        bleMetadata: {},
        readStored: (_) async => 'stored-key',
      );
      expect(result.key, 'cached-key');
      expect(result.source, DeviceApiKeySource.deviceCache);
    });

    test('falls back to secure storage and hydrates device', () async {
      final device = _testDevice();
      final result = await DeviceApiKeyResolver.resolve(
        device: device,
        bleMetadata: null,
        readStored: (_) async => 'stored-key',
      );
      expect(result.key, 'stored-key');
      expect(result.source, DeviceApiKeySource.secureStorage);
      expect(device.apiKey, 'stored-key');
    });

    test('returns missing when no source has a key', () async {
      final device = _testDevice();
      final result = await DeviceApiKeyResolver.resolve(
        device: device,
        readStored: (_) async => null,
      );
      expect(result.hasKey, isFalse);
      expect(result.source, DeviceApiKeySource.missing);
    });

    test('extracts device.api.key from portable firmware shape', () async {
      final device = _testDevice();
      final result = await DeviceApiKeyResolver.resolve(
        device: device,
        bleMetadata: {
          'device': {
            'api': {'key': 'portable-key'},
          },
        },
      );
      expect(result.key, 'portable-key');
      expect(result.source, DeviceApiKeySource.bleMetadata);
    });
  });
}
