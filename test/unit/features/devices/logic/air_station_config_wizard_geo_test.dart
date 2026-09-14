import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/logic/air_station_config_wizard_controller.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  const bleName = 'Luftdaten.at-wizard-geo';

  setUp(() async {
    initDeviceWidgetTestHarness();
    await GetStorage.init('air-station-wizard');
    AirStationConfigWizardController.resetForTests();
    AirStationConfigWizardController.removeController(bleName);
  });

  tearDown(() {
    AirStationConfigWizardController.removeController(bleName);
    AirStationConfigWizardController.resetForTests();
  });

  group('isValidGeoCoordinate', () {
    test('rejects null island and non-finite values', () {
      expect(
        AirStationConfigWizardController.isValidGeoCoordinate(0, 0),
        isFalse,
      );
      expect(
        AirStationConfigWizardController.isValidGeoCoordinate(
          double.nan,
          16.0,
        ),
        isFalse,
      );
      expect(
        AirStationConfigWizardController.isValidGeoCoordinate(91, 0),
        isFalse,
      );
      expect(
        AirStationConfigWizardController.isValidGeoCoordinate(0, 181),
        isFalse,
      );
    });

    test('accepts real coordinates', () {
      expect(
        AirStationConfigWizardController.isValidGeoCoordinate(48.21, 16.37),
        isTrue,
      );
    });
  });

  group('getCurrentLocation', () {
    test('updates currentPosition and notifies listeners', () async {
      final ctrl = AirStationConfigWizardController.createForTest(bleName);
      var notifications = 0;
      ctrl.addListener(() => notifications++);

      ctrl.getCurrentPositionForTest = () async => Position(
            latitude: 48.21,
            longitude: 16.37,
            timestamp: DateTime.utc(2026, 1, 1),
            altitude: 180.0,
            accuracy: 5.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );

      await ctrl.getCurrentLocation();

      expect(ctrl.currentPosition.latitude, 48.21);
      expect(ctrl.currentPosition.longitude, 16.37);
      expect(ctrl.currentPosition.altitude, 180.0);
      expect(notifications, greaterThan(0));
    });
  });

  group('confirmLocationFromWizard', () {
    test('persists valid coordinates and advances stage', () async {
      final ctrl = AirStationConfigWizardController.createForTest(bleName);
      ctrl.config = AirStationConfig.defaultConfig(bleName);

      ctrl.confirmLocationFromWizard(
        longitude: 16.37,
        latitude: 48.21,
        height: 180.0,
      );

      expect(ctrl.config!.longitude, 16.37);
      expect(ctrl.config!.latitude, 48.21);
      expect(ctrl.config!.height, 180.0);
      expect(ctrl.stage, AirStationConfigWizardStage.configureWifiChoice);

      final saved = GetStorage('air-station-wizard').read('active') as List;
      final entry = saved.first as Map;
      final configJson = entry['config'] as Map;
      expect(configJson['latitude'], 48.21);
      expect(configJson['longitude'], 16.37);
    });

    test('ignores invalid coordinates', () {
      final ctrl = AirStationConfigWizardController.createForTest(bleName);
      ctrl.config = AirStationConfig.defaultConfig(bleName);
      ctrl.stage = AirStationConfigWizardStage.setLocation;

      ctrl.confirmLocationFromWizard(
        longitude: 0,
        latitude: 0,
        height: 0,
      );

      expect(ctrl.config!.latitude, isNull);
      expect(ctrl.config!.longitude, isNull);
      expect(ctrl.stage, AirStationConfigWizardStage.setLocation);
    });
  });
}
