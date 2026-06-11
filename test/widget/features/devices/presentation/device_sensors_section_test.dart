import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_profile.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_sensors_section.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  setUp(() async => setUpDeviceWidgetTests(
        storageBucket: 'device_sensors_section_tests',
        mockBleEnabled: true,
        registerBleController: true,
      ));

  tearDown(tearDownDeviceWidgetTests);

  testWidgets('loading state shows spinner and loading text', (tester) async {
    final device = BleDevice(
      model: LDDeviceModel.aRound,
      bleName: 'Luftdaten.at-000000000001',
      bleMacAddress: '000000000001',
      deviceOriginalDisplayName: 'Air aRound 1',
    );

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceSensorsSection(device: device, isLoading: true),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Sensoren werden geladen'), findsOneWidget);
  });

  testWidgets('connected with empty sensors shows unavailable message', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    device.state = BleDeviceState.connected;
    device.availableSensors = [];

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceSensorsSection(device: device, isLoading: false),
      ),
    );

    expect(find.textContaining('Keine Sensorinformationen verfügbar'), findsOneWidget);
  });

  testWidgets('connected mock profile shows serial without inline firmware', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;
    MockBleGatt.initForDevice(device);
    await BleController().refreshDeviceInfo(device);

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceSensorsSection(device: device, isLoading: false),
      ),
    );

    expect(find.textContaining('Sensor-Firmware:'), findsNothing);
    expect(find.textContaining('MOCK-SEN5X'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsWidgets);
  });

  testWidgets('info button opens dialog with sensor firmware details', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;
    MockBleGatt.initForDevice(device);
    await BleController().refreshDeviceInfo(device);

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceSensorsSection(device: device, isLoading: false),
      ),
    );

    await tester.tap(find.byIcon(Icons.info_outline).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Sensor-Firmware: 1.0'), findsOneWidget);
    expect(find.textContaining('Hardware-Version: 1.0'), findsOneWidget);
    expect(find.textContaining('Protokoll-Version: 1.0'), findsOneWidget);
  });
}
