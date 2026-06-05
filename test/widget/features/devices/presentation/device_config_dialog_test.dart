import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_store.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/device_manager_page.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await setUpDeviceWidgetTests(
      storageBucket: 'device_config_dialog_tests',
      mockBleEnabled: true,
    );
  });

  tearDown(tearDownDeviceWidgetTests);

  testWidgets('DeviceConfigDialog prefills measurement interval from secure snapshot', (tester) async {
    final device = BleDevice(
      model: LDDeviceModel.aRound,
      bleName: 'Luftdaten.at-port-prefill',
      bleMacAddress: '000000000030',
      deviceOriginalDisplayName: 'Air aRound 30',
      measurementInterval: 10,
    );

    await DeviceConfigStore.instance.writePortableConfig(
      const PortableDeviceConfig(
        bleName: 'Luftdaten.at-port-prefill',
        measurementInterval: 30,
        autoReconnect: false,
        userAssignedName: 'Saved Name',
        lastConfiguredAt: null,
      ),
    );

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => DeviceConfigDialog(device: device),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('30 Sekunden'), findsOneWidget);
  });
}
