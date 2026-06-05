import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_profile.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_list_tile.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  setUp(() async => setUpDeviceWidgetTests(
        storageBucket: 'device_list_tile_tests',
        mockBleEnabled: true,
      ));

  tearDown(tearDownDeviceWidgetTests);

  testWidgets('DeviceListTile fires onTap when tapped', (tester) async {
    final device = BleDevice(
      model: LDDeviceModel.aRound,
      bleName: 'Luftdaten.at-000000000001',
      bleMacAddress: '000000000001',
      deviceOriginalDisplayName: 'Air aRound 1',
    );

    var opened = false;

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceListTile(
          device: device,
          isStation: false,
          onTap: () => opened = true,
        ),
      ),
    );

    expect(find.text('Air aRound'), findsOneWidget);
    await tester.tap(find.text('Air aRound'));
    expect(opened, isTrue);
  });

  testWidgets('portable subtitle strips Air aRound prefix', (tester) async {
    final device = BleDevice(
      model: LDDeviceModel.aRound,
      bleName: 'Luftdaten.at-000000000001',
      bleMacAddress: '000000000001',
      deviceOriginalDisplayName: 'Air aRound 1',
      userAssignedName: 'Air aRound 1',
    );

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceListTile(
          device: device,
          isStation: false,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('connected device shows Verbunden status label', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceListTile(
          device: device,
          isStation: false,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Verbunden'), findsOneWidget);
  });

  testWidgets('station with notices shows compact warning icon', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;
    device.operationalNotices = const [
      BleDeviceNotice(id: 'config_incomplete', severity: BleNoticeSeverity.warning),
    ];

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceListTile(
          device: device,
          isStation: true,
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}
