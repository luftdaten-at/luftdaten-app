import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';

class _SpyTripController extends TripController {
  int stopTripCalls = 0;

  @override
  void stopTrip() {
    stopTripCalls++;
    isOngoing = false;
    currentTripStartedAt = null;
  }
}

void main() {
  late DeviceManager manager;

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
    FlutterSecureStorage.setMockInitialValues({});
    await GetStorage.init('devices');
    GetStorage('devices').remove('devices');
    getIt.reset();
    manager = DeviceManager();
    getIt.registerSingleton<DeviceManager>(manager);
    getIt.registerSingleton<BatteryInfoAggregator>(BatteryInfoAggregator());
    getIt.registerSingleton<TripController>(_SpyTripController());
  });

  tearDown(() {
    getIt.reset();
  });

  BleDevice testDevice({
    String bleName = 'Luftdaten.at-X-1',
    String bleMacAddress = 'AABBCCDDEEFF',
    BleDeviceState state = BleDeviceState.disconnected,
  }) {
    final device = BleDevice(
      model: LDDeviceModel.aRound,
      bleName: bleName,
      bleMacAddress: bleMacAddress,
      deviceOriginalDisplayName: bleName,
    );
    if (state != BleDeviceState.disconnected) {
      device.state = state;
    }
    return device;
  }

  group('DeviceManager', () {
    test('addDevice adds to list and saves', () {
      final device = testDevice();
      manager.addDevice(device);
      expect(manager.devices, [device]);
    });

    test('deleteDevice removes and saves', () async {
      final device = testDevice();
      manager.addDevice(device);
      manager.deleteDevice(device);
      await Future<void>.delayed(Duration.zero);
      expect(manager.devices, isEmpty);
    });

    test('deleteDevice disconnects all connected devices', () {
      final connected = testDevice(state: BleDeviceState.connected);
      final other = testDevice(
        bleName: 'Luftdaten.at-X-2',
        bleMacAddress: '112233445566',
        state: BleDeviceState.connected,
      );
      manager.addDevice(connected);
      manager.addDevice(other);

      manager.deleteDevice(connected);

      expect(other.state, BleDeviceState.disconnected);
      expect(manager.devices, [other]);
    });

    test('deleteDevice stops ongoing measurement', () {
      final device = testDevice(state: BleDeviceState.connected);
      manager.addDevice(device);
      final trips = getIt<TripController>() as _SpyTripController;
      trips.isOngoing = true;

      manager.deleteDevice(device);

      expect(trips.stopTripCalls, 1);
      expect(trips.isOngoing, isFalse);
      expect(manager.devices, isEmpty);
    });

    test('addDeviceByCode parses valid QR code', () {
      final code = 'Luftdaten.at-AABBCCDDEEFF-1;Luftdaten.at-AABBCCDDEEFF-1;1';
      final device = manager.addDeviceByCode(code);
      expect(device, isNotNull);
      expect(device!.bleName, 'Luftdaten.at-AABBCCDDEEFF-1');
      expect(device.deviceOriginalDisplayName, 'Luftdaten.at-AABBCCDDEEFF-1');
      expect(device.model, LDDeviceModel.aRound);
      expect(device.bleMacAddress, 'AABBCCDDEEFF');
    });

    test('addDeviceByCode returns existing device when bleName matches', () {
      final code = 'Luftdaten.at-AABBCCDDEEFF-1;Luftdaten.at-AABBCCDDEEFF-1;1';
      final first = manager.addDeviceByCode(code);
      final second = manager.addDeviceByCode(code);
      expect(first, second);
      expect(manager.devices.length, 1);
    });

    test('addDeviceByCode returns null for invalid code', () {
      expect(manager.addDeviceByCode(null), isNull);
      expect(manager.addDeviceByCode('invalid'), isNull);
      expect(manager.addDeviceByCode('too;few'), isNull);
    });
  });
}
