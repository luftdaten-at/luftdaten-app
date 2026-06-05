import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_profile.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/device_detail_page.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  setUp(() async => setUpDeviceWidgetTests(
        storageBucket: 'device_detail_page_tests',
        registerBleController: true,
        mockBleEnabled: true,
      ));

  tearDown(tearDownDeviceWidgetTests);

  testWidgets('shows notices and sensors after bootstrap on connected mock station', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;

    await pumpDeviceApp(tester, DeviceDetailPage(device: device, isStation: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('MOCK-SEN5X'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
  });

  testWidgets('portable connected mock shows both sections with firmware in Geräteinfo', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;

    await pumpDeviceApp(tester, DeviceDetailPage(device: device, isStation: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Sensoren'), findsOneWidget);
    expect(find.text('Geräteinfo'), findsOneWidget);
    expect(find.textContaining('Name:'), findsOneWidget);
    expect(find.textContaining('Adresse:'), findsOneWidget);
    expect(find.textContaining('Firmware-Version:'), findsOneWidget);
    expect(find.textContaining('MOCK-SEN5X'), findsOneWidget);
    expect(find.text('Geräte-Info'), findsNothing);
  });

  testWidgets('disconnected device shows connection failure banner after bootstrap', (tester) async {
    final device = BleDevice(
      model: LDDeviceModel.aRound,
      bleName: 'Luftdaten.at-000000000099',
      bleMacAddress: '000000000099',
      deviceOriginalDisplayName: 'Air aRound 99',
    );
    device.state = BleDeviceState.notFound;

    await pumpDeviceApp(tester, DeviceDetailPage(device: device, isStation: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));

    expect(find.textContaining('Nicht in der Nähe'), findsWidgets);
  });

  testWidgets('station hides Startup BLE by default and shows when enabled', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;

    await pumpDeviceApp(tester, DeviceDetailPage(device: device, isStation: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Startup (BLE)'), findsNothing);

    AppSettings.I.showAirStationStartupBleInDeviceOverview = true;
    await tester.pumpWidget(
      buildDeviceTestApp(DeviceDetailPage(device: device, isStation: true)),
    );
    await tester.pump();

    expect(find.textContaining('Startup (BLE)'), findsOneWidget);
  });

  testWidgets('auto-connects mock portable device on open', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );

    await pumpDeviceApp(tester, DeviceDetailPage(device: device, isStation: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(device.state, BleDeviceState.connected);
    expect(find.textContaining('MOCK-SEN5X'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });
}
