import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_profile.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_sensors_section.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  setUp(() async => setUpDeviceWidgetTests(
        storageBucket: 'device_sensors_section_tests',
        mockBleEnabled: true,
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

  testWidgets('connected with mock profile shows sensor serial without firmware', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceSensorsSection(device: device, isLoading: false),
      ),
    );

    expect(find.textContaining('Firmware-Version:'), findsNothing);
    expect(find.textContaining('MOCK-SEN5X'), findsOneWidget);
  });
}
