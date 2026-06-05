import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('writeStationConfig and readStationConfig roundtrip', () async {
    final config = AirStationConfig(
      id: 'Luftdaten.at-test01',
      autoUpdateMode: AutoUpdateMode.on,
      batterySaverMode: BatterySaverMode.normal,
      measurementInterval: AirStationMeasurementInterval.min5,
      longitude: 16.0,
      latitude: 48.0,
      height: 200.0,
      deviceId: 'dev-abc',
    );
    final lastAt = DateTime(2026, 5, 31, 14, 30);

    await DeviceConfigStore.instance.writeStationConfig(
      config,
      lastConfiguredAt: lastAt,
    );

    final record =
        await DeviceConfigStore.instance.readStationConfig('Luftdaten.at-test01');
    expect(record, isNotNull);
    expect(record!.config.deviceId, 'dev-abc');
    expect(record.lastConfiguredAt, lastAt);
    expect(await DeviceConfigStore.instance.listStationConfigIds(),
        contains('Luftdaten.at-test01'));
  });

  test('writePortableConfig and readPortableConfig roundtrip', () async {
    final portable = PortableDeviceConfig(
      bleName: 'Luftdaten.at-port01',
      measurementInterval: 10,
      autoReconnect: true,
      userAssignedName: 'My aRound',
      lastConfiguredAt: DateTime(2026, 1, 1),
    );

    await DeviceConfigStore.instance.writePortableConfig(portable);
    final read = await DeviceConfigStore.instance.readPortableConfig('Luftdaten.at-port01');

    expect(read, isNotNull);
    expect(read!.measurementInterval, 10);
    expect(read.userAssignedName, 'My aRound');
    expect(read.lastConfiguredAt, DateTime(2026, 1, 1));
  });

  test('loadSavedForEdit returns independent clone from secure store', () async {
    final config = AirStationConfig(
      id: 'Luftdaten.at-edit01',
      autoUpdateMode: AutoUpdateMode.on,
      batterySaverMode: BatterySaverMode.normal,
      measurementInterval: AirStationMeasurementInterval.min5,
      longitude: null,
      latitude: null,
      height: null,
      deviceId: 'saved-device-id',
    );
    await DeviceConfigStore.instance.writeStationConfig(config);

    final clone = await AirStationConfigManager.loadSavedForEdit('Luftdaten.at-edit01');
    expect(clone, isNotNull);
    expect(clone!.deviceId, 'saved-device-id');

    clone.measurementInterval = AirStationMeasurementInterval.min10;
    final again = await DeviceConfigStore.instance.readStationConfig('Luftdaten.at-edit01');
    expect(again!.config.measurementInterval, AirStationMeasurementInterval.min5);
  });

  test('migrateFromSharedPreferencesIfNeeded moves legacy prefs to secure store', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'air_station_config_Luftdaten.at-legacy',
      '{"id":"Luftdaten.at-legacy","autoUpdateMode":3,"batterySaverMode":1,'
      '"measurementInterval":300,"longitude":null,"latitude":null,"height":null,'
      '"deviceId":"legacy-id","mqttEnabled":false,"mqttPort":1883,"mqttUseTls":false,'
      '"syncRtcFromNtp":false,"detectModelFromSensors":false,"uploadSdLogToDatahub":false,'
      '"clearSdCard":false,"refreshSensors":false}',
    );

    await DeviceConfigStore.instance.migrateFromSharedPreferencesIfNeeded();

    final record =
        await DeviceConfigStore.instance.readStationConfig('Luftdaten.at-legacy');
    expect(record, isNotNull);
    expect(record!.config.deviceId, 'legacy-id');
    expect(prefs.getString('air_station_config_Luftdaten.at-legacy'), isNull);

    await DeviceConfigStore.instance.migrateFromSharedPreferencesIfNeeded();
    expect(await DeviceConfigStore.instance.listStationConfigIds(),
        contains('Luftdaten.at-legacy'));
  });
}
