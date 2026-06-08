import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/device_error.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  setUpAll(() {
    initDeviceWidgetTestHarness();
  });

  setUp(() async {
    await setUpDeviceWidgetTests(
      storageBucket: 'ble_controller_refresh_tests',
      mockBleEnabled: true,
    );
  });

  tearDown(tearDownDeviceWidgetTests);

  test('refreshDeviceInfo clears stale errors and repopulates mock station data', () async {
    if (!getIt.isRegistered<BatteryInfoAggregator>()) {
      getIt.registerSingleton<BatteryInfoAggregator>(BatteryInfoAggregator());
    }

    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    device.state = BleDeviceState.connected;
    device.errors.add(SensorNotFoundError(LDSensor.sen5x));
    device.availableSensors = [];
    device.operationalNotices = [];

    MockBleGatt.initForDevice(device);
    await BleController().refreshDeviceInfo(device);

    expect(device.errors, isEmpty);
    expect(device.availableSensors, isNotEmpty);
    expect(
      device.operationalNotices.any((n) => n.id == 'config_incomplete'),
      isTrue,
    );
    expect(device.availableSensors!.first.serialNumber, 'MOCK-SEN5X');
  });
}
