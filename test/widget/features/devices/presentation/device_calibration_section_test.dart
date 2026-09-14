import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';
import 'package:luftdaten.at/features/devices/logic/device_calibration_store.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_calibration_section.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/body_heat_calibration.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

Future<void> _pumpCalibrationSection(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(
    I18n(
      initialLocale: const Locale('de'),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

void main() {
  late DeviceCalibrationStore store;

  setUpAll(() async {
    initDeviceWidgetTestHarness();
    await GetStorage.init('deviceCalibration');
    await GetStorage.init('bodyHeatCalibration');
    await BodyHeatCalibrationStore.instance.init();
  });

  setUp(() async {
    GetStorage('deviceCalibration').erase();
    store = DeviceCalibrationStore();
    await store.init();
  });

  testWidgets('shows body heat calibration on connected badge', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.badge,
      existingBleNames: const [],
    );
    device.setConnectionStateForTest(BleDeviceState.connected);
    device.availableSensors = [SensorDetails(LDSensor.shtc3)];

    await _pumpCalibrationSection(
      tester,
      DeviceCalibrationSection(
        device: device,
        isLoading: false,
        calibrationStore: store,
      ),
    );
    await tester.pump();

    expect(find.text('Kalibrierung'), findsOneWidget);
    expect(find.text('Körperwärme (UTCI)'), findsOneWidget);
  });

  testWidgets('shows CO2 calibration when SCD4x is present', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    device.setConnectionStateForTest(BleDeviceState.connected);
    device.availableSensors = [SensorDetails(LDSensor.scd4x)];

    await _pumpCalibrationSection(
      tester,
      DeviceCalibrationSection(
        device: device,
        isLoading: false,
        calibrationStore: store,
      ),
    );
    await tester.pump();

    expect(find.text('CO₂ (Frischluft)'), findsOneWidget);
    expect(find.text('Frischluft-Kalibrierung'), findsOneWidget);
  });

  testWidgets('hidden when device disconnected', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.badge,
      existingBleNames: const [],
    );
    device.setConnectionStateForTest(BleDeviceState.disconnected);
    device.availableSensors = [SensorDetails(LDSensor.shtc3)];

    await _pumpCalibrationSection(
      tester,
      DeviceCalibrationSection(
        device: device,
        isLoading: false,
        calibrationStore: store,
      ),
    );
    await tester.pump();

    expect(find.text('Kalibrierung'), findsNothing);
  });

  testWidgets('hidden when no calibratable sensors', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    device.setConnectionStateForTest(BleDeviceState.connected);
    device.availableSensors = [SensorDetails(LDSensor.sds011)];

    await _pumpCalibrationSection(
      tester,
      DeviceCalibrationSection(
        device: device,
        isLoading: false,
        calibrationStore: store,
      ),
    );
    await tester.pump();

    expect(find.text('Kalibrierung'), findsNothing);
  });
}
