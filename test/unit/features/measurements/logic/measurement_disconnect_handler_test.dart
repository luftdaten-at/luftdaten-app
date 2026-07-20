import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/background_services/background_service.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_disconnect_handler.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

class _FakeBackgroundService extends BackgroundService {
  var stopTripCalls = 0;

  @override
  void init() {}

  @override
  Future<bool> startTrip(int interval) async => true;

  @override
  void stopTrip() => stopTripCalls++;

  @override
  void exit() {}
}

BleDevice _testDevice() => BleDevice(
      model: LDDeviceModel.aRound,
      bleName: 'Luftdaten.at-TEST-1',
      bleMacAddress: 'AABBCCDDEEFF',
      deviceOriginalDisplayName: 'Luftdaten.at-TEST-1',
    );

void _startOngoingTrip(TripController controller, BleDevice device) {
  controller.ongoingTrips[device] = Trip(
    deviceDisplayName: device.displayName,
    deviceFourLetterCode: device.fourLetterCode,
    deviceModel: device.model,
    deviceChipId: ChipId.fromChipId(device.chipIdForApi),
  );
  controller.isOngoing = true;
  controller.currentTripStartedAt =
      DateTime.now().subtract(const Duration(minutes: 1));
}

void main() {
  setUpAll(initDeviceWidgetTestHarness);

  group('MeasurementDisconnectHandler', () {
    late TripController trips;
    late BleDevice device;
    late MeasurementDisconnectHandler handler;
    late _FakeBackgroundService backgroundService;
    var connectCalls = 0;
    var allowConnect = false;

    setUp(() async {
      await setUpDeviceWidgetTests(
        storageBucket: 'measurement_disconnect_handler_tests',
      );
      backgroundService = _FakeBackgroundService();
      getIt.registerSingleton<BackgroundService>(backgroundService);

      trips = TripController();
      device = _testDevice();
      _startOngoingTrip(trips, device);
      device.setConnectionStateForTest(BleDeviceState.disconnected);

      connectCalls = 0;
      allowConnect = false;
      handler = MeasurementDisconnectHandler(
        tripController: () => trips,
        reconnectInterval: const Duration(hours: 1),
        connectDevice: (d) async {
          connectCalls++;
          if (allowConnect) {
            d.setConnectionStateForTest(BleDeviceState.connected);
            return true;
          }
          return false;
        },
      );
    });

    tearDown(() {
      handler.cancelReconnect();
      tearDownDeviceWidgetTests();
    });

    test('handleDisconnect pauses trip and starts reconnect timer', () async {
      handler.handleDisconnect(device);
      await Future<void>.delayed(Duration.zero);

      expect(trips.isPausedForDisconnect, isTrue);
      expect(trips.disconnectPausedDevice, same(device));
      expect(handler.hasReconnectTimerForTest, isTrue);
      expect(trips.isOngoing, isTrue);
    });

    test('reconnect success resumes trip', () async {
      handler.handleDisconnect(device);
      await Future<void>.delayed(Duration.zero);
      expect(trips.isPausedForDisconnect, isTrue);

      device.setConnectionStateForTest(BleDeviceState.connected);
      await handler.attemptReconnectForTest(device);

      expect(trips.isPausedForDisconnect, isFalse);
      expect(trips.elapsedBeforePause, isNull);
      expect(handler.hasReconnectTimerForTest, isFalse);
    });

    test('reconnect via connect callback resumes trip', () async {
      handler.handleDisconnect(device);
      await Future<void>.delayed(Duration.zero);

      allowConnect = true;
      await handler.attemptReconnectForTest(device);

      expect(trips.isPausedForDisconnect, isFalse);
      expect(connectCalls, greaterThanOrEqualTo(1));
    });

    test('stopMeasurementFromDialog stops trip and cancels reconnect', () {
      handler.handleDisconnect(device);

      handler.stopMeasurementFromDialog();

      expect(trips.isOngoing, isFalse);
      expect(trips.isPausedForDisconnect, isFalse);
      expect(handler.hasReconnectTimerForTest, isFalse);
      expect(backgroundService.stopTripCalls, 1);
    });
  });
}
