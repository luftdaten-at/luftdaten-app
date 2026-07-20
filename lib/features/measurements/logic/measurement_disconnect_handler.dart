import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/config/env.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_paused_dialog.dart';

/// Pauses an ongoing trip on BLE disconnect, shows a reconnect dialog, and retries connect.
class MeasurementDisconnectHandler {
  MeasurementDisconnectHandler({
    TripController Function()? tripController,
    Future<bool> Function(BleDevice device)? connectDevice,
    Duration reconnectInterval = const Duration(seconds: 5),
  })  : _tripController = tripController ?? (() => getIt<TripController>()),
        _connectDevice =
            connectDevice ?? ((device) => device.connect(showNoticesOnConnect: false)),
        _reconnectInterval = reconnectInterval;

  final TripController Function() _tripController;
  final Future<bool> Function(BleDevice device) _connectDevice;
  final Duration _reconnectInterval;

  Timer? _reconnectTimer;
  bool _dialogOpen = false;
  bool _reconnectInFlight = false;

  TripController get _trips => _tripController();

  void handleDisconnect(BleDevice device) {
    if (!_trips.isOngoing || !_trips.ongoingTrips.containsKey(device)) return;
    if (_trips.isPausedForDisconnect && _trips.disconnectPausedDevice == device) {
      return;
    }

    logger.d('MeasurementDisconnectHandler: pausing trip for ${device.bleName}');
    _trips.pauseForBleDisconnect(device);
    _showDialogIfNeeded();
    _startReconnectLoop(device);
    unawaited(_attemptReconnect(device));
  }

  void stopMeasurementFromDialog() {
    cancelReconnect();
    _trips.stopTrip();
  }

  void cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _dismissDialog();
  }

  void _startReconnectLoop(BleDevice device) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(_reconnectInterval, (_) {
      unawaited(_attemptReconnect(device));
    });
  }

  Future<void> _attemptReconnect(BleDevice device) async {
    if (!_trips.isOngoing || !_trips.isPausedForDisconnect) {
      cancelReconnect();
      return;
    }
    if (_trips.disconnectPausedDevice != device) return;
    if (device.state == BleDeviceState.connected) {
      _onReconnectSuccess();
      return;
    }
    if (_reconnectInFlight || device.state == BleDeviceState.connecting) {
      return;
    }

    _reconnectInFlight = true;
    try {
      logger.d('MeasurementDisconnectHandler: reconnect attempt for ${device.bleName}');
      final ok = await _connectDevice(device);
      if (ok && device.state == BleDeviceState.connected) {
        _onReconnectSuccess();
      }
    } catch (e, st) {
      logger.d('MeasurementDisconnectHandler: reconnect failed: $e $st');
    } finally {
      _reconnectInFlight = false;
    }
  }

  void _onReconnectSuccess() {
    if (!_trips.isPausedForDisconnect) return;
    logger.d('MeasurementDisconnectHandler: reconnected, resuming trip');
    _trips.resumeAfterBleReconnect();
    cancelReconnect();
  }

  void _showDialogIfNeeded() {
    if (_dialogOpen) return;
    final context = _appContext;
    if (context == null) return;

    _dialogOpen = true;
    showMeasurementPausedDialog(
      context,
      onStopMeasurement: stopMeasurementFromDialog,
    ).whenComplete(() {
      _dialogOpen = false;
    });
  }

  void _dismissDialog() {
    if (!_dialogOpen) return;
    final context = _appContext;
    if (context != null && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    _dialogOpen = false;
  }

  BuildContext? get _appContext {
    try {
      return globalKey.currentContext;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  bool get isDialogOpenForTest => _dialogOpen;

  @visibleForTesting
  bool get hasReconnectTimerForTest => _reconnectTimer != null;

  @visibleForTesting
  Future<void> attemptReconnectForTest(BleDevice device) => _attemptReconnect(device);
}
