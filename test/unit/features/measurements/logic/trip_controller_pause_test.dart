import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/background_services/background_service.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_disconnect_handler.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';

class _FakeBackgroundService extends BackgroundService {
  bool stopCalled = false;

  @override
  void init() {}

  @override
  Future<bool> startTrip(int interval) async => true;

  @override
  void stopTrip() => stopCalled = true;

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
      DateTime.now().subtract(const Duration(minutes: 2));
}

void main() {
  group('TripController pause for BLE disconnect', () {
    late TripController controller;
    late BleDevice device;

    setUp(() {
      controller = TripController();
      device = _testDevice();
      _startOngoingTrip(controller, device);
    });

    test('pauseForBleDisconnect sets flags and keeps isOngoing', () {
      controller.pauseForBleDisconnect(device);

      expect(controller.isPausedForDisconnect, isTrue);
      expect(controller.disconnectPausedDevice, same(device));
      expect(controller.elapsedBeforePause, isNotNull);
      expect(controller.elapsedBeforePause!.inMinutes, 2);
      expect(controller.isOngoing, isTrue);
    });

    test('pauseForBleDisconnect is noop when already paused', () {
      controller.pauseForBleDisconnect(device);
      final elapsed = controller.elapsedBeforePause;

      controller.pauseForBleDisconnect(device);

      expect(controller.elapsedBeforePause, elapsed);
    });

    test('resumeAfterBleReconnect restores elapsed time', () {
      controller.pauseForBleDisconnect(device);
      final frozen = controller.elapsedBeforePause!;

      controller.resumeAfterBleReconnect();

      expect(controller.isPausedForDisconnect, isFalse);
      expect(controller.elapsedBeforePause, isNull);
      expect(controller.disconnectPausedDevice, isNull);
      final resumedElapsed =
          DateTime.now().difference(controller.currentTripStartedAt!);
      expect(resumedElapsed.inSeconds, closeTo(frozen.inSeconds, 1));
    });

    test('stopTrip clears pause state and cancels reconnect', () {
      final backgroundService = _FakeBackgroundService();
      if (getIt.isRegistered<BackgroundService>()) {
        getIt.unregister<BackgroundService>();
      }
      getIt.registerSingleton<BackgroundService>(backgroundService);

      final handler = MeasurementDisconnectHandler(
        tripController: () => controller,
        reconnectInterval: const Duration(hours: 1),
        connectDevice: (_) async => false,
      );
      if (getIt.isRegistered<MeasurementDisconnectHandler>()) {
        getIt.unregister<MeasurementDisconnectHandler>();
      }
      getIt.registerSingleton<MeasurementDisconnectHandler>(handler);

      controller.pauseForBleDisconnect(device);
      handler.handleDisconnect(device);

      controller.stopTrip();

      expect(controller.isPausedForDisconnect, isFalse);
      expect(controller.elapsedBeforePause, isNull);
      expect(controller.isOngoing, isFalse);
      expect(handler.hasReconnectTimerForTest, isFalse);
      expect(backgroundService.stopCalled, isTrue);

      getIt.unregister<MeasurementDisconnectHandler>();
      getIt.unregister<BackgroundService>();
    });
  });
}
