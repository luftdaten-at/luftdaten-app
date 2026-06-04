import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/device_api_key_ble_sync.dart';
import 'package:luftdaten.at/features/devices/logic/station_secrets_store.dart';

BleDevice _testDevice() {
  return BleDevice(
    model: LDDeviceModel.station,
    bleName: 'Luftdaten.at Air Station 0001',
    bleMacAddress: 'AABBCCDDEEFF',
    deviceOriginalDisplayName: 'Air Station 0001',
  );
}

List<int> _tlv20(String key) {
  final utf = key.codeUnits;
  return [AirStationConfigFlags.API_KEY.value, utf.length, ...utf];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('DeviceApiKeyBleSync.applyFromAirStationConfigBytes', () {
    test('extracts TLV flag 20 and sets device.apiKey', () async {
      final device = _testDevice();
      final applied = await DeviceApiKeyBleSync.applyFromAirStationConfigBytes(
        device,
        _tlv20('ble-station-key'),
      );
      expect(applied, isTrue);
      expect(device.apiKey, 'ble-station-key');
      expect(
        await StationSecretsStore.instance.readApiKey(device.bleName),
        'ble-station-key',
      );
    });

    test('returns false when TLV has no API key', () async {
      final device = _testDevice();
      final applied = await DeviceApiKeyBleSync.applyFromAirStationConfigBytes(
        device,
        [AirStationConfigFlags.TZ.value, 3, ...'UTC'.codeUnits],
      );
      expect(applied, isFalse);
      expect(device.apiKey, isNull);
    });
  });

  group('DeviceApiKeyBleSync.applyFromBleMetadata', () {
    test('parses device.api.key from JSON metadata', () async {
      final device = _testDevice();
      final applied = await DeviceApiKeyBleSync.applyFromBleMetadata(
        device,
        {
          'device': {
            'api': {'key': 'json-metadata-key'},
          },
        },
      );
      expect(applied, isTrue);
      expect(device.apiKey, 'json-metadata-key');
      expect(
        await StationSecretsStore.instance.readApiKey(device.bleName),
        'json-metadata-key',
      );
    });
  });
}
