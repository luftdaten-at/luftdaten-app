import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/logic/air_station_setup_verification.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AirStationSetupVerification.resolveDeviceId', () {
    test('prefers config deviceId', () {
      final config = AirStationConfig.fromJson({
        'id': 'ble-name',
        'autoUpdateMode': 1,
        'batterySaverMode': 0,
        'measurementInterval': 300,
        'deviceId': 'ABC123SC',
      });
      expect(
        AirStationSetupVerification.resolveDeviceId(config, 'Luftdaten.at-XYZ'),
        'ABC123SC',
      );
    });

    test('falls back to ble name suffix + AAA', () {
      expect(
        AirStationSetupVerification.resolveDeviceId(
          null,
          'Luftdaten.at-0042',
        ),
        '0042AAA',
      );
    });
  });

  group('AirStationSetupVerification.distanceMeters', () {
    test('returns ~0 for identical points', () {
      final d = AirStationSetupVerification.distanceMeters(48.2, 16.37, 48.2, 16.37);
      expect(d, lessThan(1));
    });

    test('returns ~111 km per degree latitude', () {
      final d = AirStationSetupVerification.distanceMeters(48.0, 16.0, 49.0, 16.0);
      expect(d, greaterThan(100000));
      expect(d, lessThan(120000));
    });
  });

  group('AirStationSetupVerification.hasValidExpectedGeo', () {
    test('rejects null and 0,0', () {
      expect(AirStationSetupVerification.hasValidExpectedGeo(null, 16), isFalse);
      expect(AirStationSetupVerification.hasValidExpectedGeo(48, null), isFalse);
      expect(AirStationSetupVerification.hasValidExpectedGeo(0, 0), isFalse);
    });

    test('accepts normal coordinates', () {
      expect(AirStationSetupVerification.hasValidExpectedGeo(48.21, 16.37), isTrue);
    });
  });

  group('geo tolerance', () {
    test('~90m offset is within default max', () {
      final d = AirStationSetupVerification.distanceMeters(48.2, 16.37, 48.2008, 16.37);
      expect(d, lessThan(AirStationSetupVerification.geoMaxDistanceMeters));
    });

    test('1km offset exceeds default max', () {
      final d = AirStationSetupVerification.distanceMeters(48.2, 16.37, 48.21, 16.37);
      expect(d, greaterThan(AirStationSetupVerification.geoMaxDistanceMeters));
    });
  });
}
