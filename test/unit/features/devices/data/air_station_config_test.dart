import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luftdaten.at/features/devices/data/air_station_config.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AirStationConfig', () {
    test('fromJson parses all fields', () async {
      final json = {
        'id': 'station-1',
        'autoUpdateMode': 3, // on
        'batterySaverMode': 1, // normal
        'measurementInterval': 300, // min5
        'longitude': 16.37,
        'latitude': 48.21,
        'height': 180.0,
        'deviceId': 'device-123',
      };
      final config = AirStationConfig.fromJson(json);
      expect(config.id, 'station-1');
      expect(config.autoUpdateMode, AutoUpdateMode.on);
      expect(config.batterySaverMode, BatterySaverMode.normal);
      expect(config.measurementInterval, AirStationMeasurementInterval.min5);
      expect(config.longitude, 16.37);
      expect(config.latitude, 48.21);
      expect(config.height, 180.0);
      expect(config.deviceId, 'device-123');
    });

    test('toJson contains all fields', () {
      final config = AirStationConfig(
        id: 'test',
        autoUpdateMode: AutoUpdateMode.off,
        batterySaverMode: BatterySaverMode.ultra,
        measurementInterval: AirStationMeasurementInterval.sec30,
        longitude: 10.0,
        latitude: 50.0,
        height: 100.0,
        deviceId: 'dev-1',
      );
      final json = config.toJson();
      expect(json['id'], 'test');
      expect(json['autoUpdateMode'], 0);
      expect(json['batterySaverMode'], 3);
      expect(json['measurementInterval'], 30);
      expect(json['longitude'], 10.0);
      expect(json['latitude'], 50.0);
      expect(json['height'], 100.0);
      expect(json['deviceId'], 'dev-1');
    });

    test('defaultConfig creates config with defaults', () {
      final config = AirStationConfig.defaultConfig('new-id');
      expect(config.id, 'new-id');
      expect(config.autoUpdateMode, AutoUpdateMode.on);
      expect(config.batterySaverMode, BatterySaverMode.normal);
      expect(config.measurementInterval, AirStationMeasurementInterval.min5);
      expect(config.longitude, isNull);
      expect(config.latitude, isNull);
      expect(config.height, isNull);
      expect(config.deviceId, isNull);
    });
  });

  group('AirStationWifiConfig', () {
    test('fromJson and toJson roundtrip', () {
      final original = AirStationWifiConfig(ssid: 'MyNetwork', password: 'secret123');
      final json = original.toJson();
      final restored = AirStationWifiConfig.fromJson(json);
      expect(restored.ssid, 'MyNetwork');
      expect(restored.password, 'secret123');
    });

    test('valid is false when ssid too short', () {
      final config = AirStationWifiConfig(ssid: 'A', password: 'password1');
      expect(config.valid, isFalse);
    });

    test('valid is false when password too short', () {
      final config = AirStationWifiConfig(ssid: 'MySSID', password: 'short');
      expect(config.valid, isFalse);
    });

    test('valid is true when both meet requirements', () {
      final config = AirStationWifiConfig(ssid: 'MySSID', password: 'password123');
      expect(config.valid, isTrue);
    });

    test('toBytes encodes ssid and password', () {
      final config = AirStationWifiConfig(ssid: 'AB', password: '12345678');
      final bytes = config.toBytes();
      expect(bytes[0], 6); // ssid flag
      expect(bytes[1], 2); // ssid length
      expect(bytes.sublist(2, 4), [65, 66]); // 'AB'
      expect(bytes[4], 7); // password flag
      expect(bytes[5], 8); // password length
    });
  });

  group('AutoUpdateMode', () {
    test('parseBinary returns correct mode', () {
      expect(AutoUpdateMode.parseBinary(3), AutoUpdateMode.on);
      expect(AutoUpdateMode.parseBinary(2), AutoUpdateMode.critical);
      expect(AutoUpdateMode.parseBinary(0), AutoUpdateMode.off);
      expect(AutoUpdateMode.parseBinary(99), AutoUpdateMode.on); // fallback
    });
  });

  group('BatterySaverMode', () {
    test('parseBinary returns correct mode', () {
      expect(BatterySaverMode.parseBinary(3), BatterySaverMode.ultra);
      expect(BatterySaverMode.parseBinary(1), BatterySaverMode.normal);
      expect(BatterySaverMode.parseBinary(0), BatterySaverMode.off);
      expect(BatterySaverMode.parseBinary(99), BatterySaverMode.normal); // fallback
    });
  });

  group('AirStationMeasurementInterval', () {
    test('parseSeconds returns correct interval', () {
      expect(AirStationMeasurementInterval.parseSeconds(30), AirStationMeasurementInterval.sec30);
      expect(AirStationMeasurementInterval.parseSeconds(300), AirStationMeasurementInterval.min5);
      expect(AirStationMeasurementInterval.parseSeconds(3600), AirStationMeasurementInterval.h1);
      expect(AirStationMeasurementInterval.parseSeconds(999), AirStationMeasurementInterval.min5); // fallback
    });
  });
}
