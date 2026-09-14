import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/logic/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/features/map/presentation/widgets/map_select_marker.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

Future<void> _tapWeiter(WidgetTester tester) async {
  final button = find.byType(FilledButton);
  await tester.scrollUntilVisible(
    button,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  const bleName = 'Luftdaten.at-map-screen';

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

  testWidgets('MapScreen applies mocked GPS coordinates to fields', (tester) async {
    final ctrl = AirStationConfigWizardController.createForTest(bleName);
    ctrl.config = AirStationConfig.defaultConfig(bleName);
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

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(controller: ctrl),
      ),
    );
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.elementAt(0).controller!.text, '16.37');
    expect(fields.elementAt(1).controller!.text, '48.21');
    expect(fields.elementAt(2).controller!.text, '180.0');
  });

  testWidgets('Weiter rejects 0,0 and accepts valid coordinates', (tester) async {
    final ctrl = AirStationConfigWizardController.createForTest(bleName);
    ctrl.config = AirStationConfig.defaultConfig(bleName);
    ctrl.stage = AirStationConfigWizardStage.setLocation;

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(controller: ctrl),
      ),
    );
    await tester.pumpAndSettle();

    await _tapWeiter(tester);

    expect(ctrl.stage, AirStationConfigWizardStage.setLocation);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '16.37');
    await tester.enterText(fields.at(1), '48.21');
    await tester.pumpAndSettle();

    await _tapWeiter(tester);

    expect(ctrl.stage, AirStationConfigWizardStage.configureWifiChoice);
    expect(ctrl.config!.latitude, 48.21);
    expect(ctrl.config!.longitude, 16.37);
  });
}
