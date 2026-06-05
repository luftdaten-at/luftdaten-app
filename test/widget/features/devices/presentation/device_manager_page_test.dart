import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_profile.dart';
import 'package:luftdaten.at/core/widgets/dashboard_list_tile.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/device_detail_page.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/device_manager_page.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_list_tile.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  setUp(() async => setUpDeviceWidgetTests(
        storageBucket: 'device_manager_page_tests',
        registerBleController: true,
        mockBleEnabled: true,
      ));

  tearDown(tearDownDeviceWidgetTests);

  testWidgets('empty state shows add-device tile when BLE is ready', (tester) async {
    DeviceManagerPage.debugBleStatus = BleStatus.ready;

    await pumpDeviceApp(tester, const DeviceManagerPage());
    await tester.pump();

    expect(
      find.textContaining('Du hast noch kein Gerät aktiviert'),
      findsOneWidget,
    );
    expect(find.byType(DashboardListTile), findsOneWidget);
    expect(find.text('Neues Gerät hinzufügen'), findsWidgets);
  });

  testWidgets('populated list shows section headings and bottom add button', (tester) async {
    DeviceManagerPage.debugBleStatus = BleStatus.ready;
    final manager = getIt<DeviceManager>();

    final aRound = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    final station = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: [aRound.bleName],
    );
    manager.addDevice(aRound);
    manager.addDevice(station);
    await tester.pump();

    await pumpDeviceApp(tester, const DeviceManagerPage(), manager: manager);
    await tester.pump();

    expect(find.text('Air aRound'), findsNWidgets(2));
    expect(find.text('Air Station'), findsNWidgets(2));
    expect(find.widgetWithIcon(FilledButton, Icons.qr_code), findsOneWidget);
  });

  testWidgets('tapping device tile opens DeviceDetailPage', (tester) async {
    DeviceManagerPage.debugBleStatus = BleStatus.unsupported;
    final manager = getIt<DeviceManager>();

    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;
    manager.addDevice(device);
    await tester.pump();

    await pumpDeviceApp(tester, const DeviceManagerPage(), manager: manager);
    await tester.pump();

    await tester.tap(find.byType(DeviceListTile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DeviceDetailPage), findsOneWidget);
  });
}
