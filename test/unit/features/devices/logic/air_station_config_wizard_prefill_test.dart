import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_store.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void _registerTestServices() {
  GetIt.instance.reset();
  getIt.registerSingleton<DeviceManager>(DeviceManager());
  getIt.registerSingleton<BatteryInfoAggregator>(BatteryInfoAggregator());
  getIt.registerSingleton<BleController>(BleController());
}

BleDevice _connectedStationDevice() {
  final manager = getIt<DeviceManager>();
  final device = BleDevice(
    model: LDDeviceModel.station,
    bleName: 'Luftdaten.at-wizard-prefill',
    bleMacAddress: 'AABBCCDDEE01',
    deviceOriginalDisplayName: 'Air Station Prefill',
  );
  manager.addDevice(device);
  device.state = BleDeviceState.connected;
  return device;
}

void main() {
  const bleName = 'Luftdaten.at-wizard-prefill';

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    initDeviceWidgetTestHarness();
    for (final bucket in ['settings', 'wizard_prefill_tests', 'devices', 'air-station-wizard']) {
      await GetStorage.init(bucket);
    }
    _registerTestServices();
    _connectedStationDevice();

    await DeviceConfigStore.instance.writeStationConfig(
      AirStationConfig(
        id: bleName,
        autoUpdateMode: AutoUpdateMode.on,
        batterySaverMode: BatterySaverMode.normal,
        measurementInterval: AirStationMeasurementInterval.min5,
        longitude: 16.0,
        latitude: 48.0,
        height: 200.0,
        deviceId: 'prefill-device-id',
      ),
    );

    AirStationConfigWizardController.resetForTests();
    AirStationConfigWizardController.debugBleStatus = BleStatus.ready;
    AirStationConfigWizardController.removeController(bleName);
  });

  tearDown(() {
    AirStationConfigWizardController.removeController(bleName);
    AirStationConfigWizardController.resetForTests();
    GetIt.instance.reset();
  });

  test('hydrateFromSavedConfig prefills editSettings without transmitting', () async {
    final ctrl = AirStationConfigWizardController.createForTest(bleName);
    await ctrl.hydrateFromSavedConfigForTest();

    expect(ctrl.config, isNotNull);
    expect(ctrl.config!.deviceId, 'prefill-device-id');
    expect(ctrl.stage, AirStationConfigWizardStage.editSettings);
    expect(ctrl.stage, isNot(AirStationConfigWizardStage.sending));
  });

  test('prefilled config on connect does not transmit without pending flag', () async {
    final ctrl = AirStationConfigWizardController.createForTest(bleName);
    await ctrl.hydrateFromSavedConfigForTest();
    _registerTestServices();
    _connectedStationDevice();

    await ctrl.onConnectedForTest();

    expect(ctrl.stage, AirStationConfigWizardStage.editSettings);
    expect(ctrl.stage, isNot(AirStationConfigWizardStage.sending));
  });

  test('armed transmit on connected device starts configuration send', () async {
    final ctrl = AirStationConfigWizardController.createForTest(bleName);
    await ctrl.hydrateFromSavedConfigForTest();
    _registerTestServices();
    _connectedStationDevice();
    ctrl.armConfigTransmitForTest();

    await ctrl.onConnectedForTest();

    expect(
      ctrl.stage,
      anyOf(
        AirStationConfigWizardStage.sending,
        AirStationConfigWizardStage.configTransmissionFailed,
        AirStationConfigWizardStage.checkLed,
      ),
    );
  });
}
