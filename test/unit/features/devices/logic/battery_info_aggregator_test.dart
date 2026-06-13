import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';

void main() {
  late BatteryInfoAggregator aggregator;
  late DeviceManager deviceManager;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') return '/tmp';
      if (methodCall.method == 'getTemporaryDirectory') return '/tmp';
      return null;
    });
  });

  setUp(() async {
    await GetStorage.init('devices');
    GetStorage('devices').remove('devices');
    GetIt.instance.reset();
    deviceManager = DeviceManager();
    GetIt.instance.registerSingleton<DeviceManager>(deviceManager);
    aggregator = BatteryInfoAggregator();
    GetIt.instance.registerSingleton<BatteryInfoAggregator>(aggregator);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  BleDevice connectedDevice() {
    final device = BleDevice(
      model: LDDeviceModel.aRound,
      bleName: 'Luftdaten.at-X-1',
      bleMacAddress: 'AABBCCDDEEFF',
      deviceOriginalDisplayName: 'Luftdaten.at-X-1',
    );
    deviceManager.addDevice(device);
    device.state = BleDeviceState.connected;
    return device;
  }

  group('BatteryInfoAggregator', () {
    test('syncFromConnectedDevices picks reportable battery on connected device', () {
      final device = connectedDevice();
      final details = BatteryDetails.fromBytes([1, 75, 37]);
      device.batteryDetails = details;

      expect(aggregator.currentBatteryDetails, details);
      expect(aggregator.show, isTrue);
      expect(aggregator.collectedBatteryDetails, contains(details));
    });

    test('show is false for faulty battery on connected device', () {
      final device = connectedDevice();
      device.batteryDetails = BatteryDetails.fromBytes([0, 0, 0]);

      expect(aggregator.show, isFalse);
      expect(aggregator.currentBatteryDetails, isNull);
    });

    test('show is false when no device connected', () {
      final device = connectedDevice();
      device.batteryDetails = BatteryDetails.fromBytes([1, 75, 37]);
      expect(aggregator.show, isTrue);

      device.state = BleDeviceState.disconnected;
      aggregator.onConnectionStatusUpdated();

      expect(aggregator.show, isFalse);
      expect(aggregator.currentBatteryDetails, isNull);
    });

    test('prefers first connected device with reportable battery', () {
      final d1 = connectedDevice();
      d1.batteryDetails = BatteryDetails.fromBytes([0, 0, 0]);

      final d2 = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-Y-2',
        bleMacAddress: '112233445566',
        deviceOriginalDisplayName: 'Luftdaten.at-Y-2',
      );
      deviceManager.addDevice(d2);
      d2.state = BleDeviceState.connected;
      final good = BatteryDetails.fromBytes([1, 90, 41]);
      d2.batteryDetails = good;

      expect(aggregator.currentBatteryDetails, good);
      expect(aggregator.show, isTrue);
    });
  });
}
