import 'dart:async';

import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_firmware_image.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/flutter_reactive_ble_transport.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';

/// OTA control command bytes (Badge firmware `ble-ota.md`).
abstract final class BleOtaCommand {
  static const int start = 0x01;
  static const int abort = 0x02;
  static const int finish = 0x03;
}

/// OTA state bytes from `ota_control` status notify.
abstract final class BleOtaState {
  static const int idle = 0;
  static const int ready = 1;
  static const int receiving = 2;
  static const int verifying = 3;
  static const int rebooting = 4;
  static const int error = 5;
}

/// OTA error bytes from status notify.
abstract final class BleOtaError {
  static const int none = 0;
  static const int busy = 1;
  static const int badSize = 2;
  static const int flash = 3;
  static const int sha = 4;
  static const int version = 5;
  static const int abort = 6;
  static const int timeout = 7;
}

class BleOtaProgress {
  const BleOtaProgress({
    required this.state,
    required this.error,
    required this.progressPct,
    required this.bytesReceived,
    required this.totalBytes,
  });

  final int state;
  final int error;
  final int progressPct;
  final int bytesReceived;
  final int totalBytes;
}

class BleOtaResult {
  const BleOtaResult._({
    required this.ok,
    this.errorMessage,
    this.confirmedVersion,
    this.cancelled = false,
  });

  final bool ok;
  final String? errorMessage;
  final FirmwareVersion? confirmedVersion;
  final bool cancelled;

  factory BleOtaResult.success(FirmwareVersion version) =>
      BleOtaResult._(ok: true, confirmedVersion: version);

  factory BleOtaResult.failure(String message) =>
      BleOtaResult._(ok: false, errorMessage: message);

  factory BleOtaResult.cancelledResult() =>
      const BleOtaResult._(ok: false, cancelled: true, errorMessage: 'Abgebrochen');
}

class BleOtaStatusFrame {
  const BleOtaStatusFrame({
    required this.state,
    required this.error,
    required this.progressPct,
    required this.bytesReceived,
  });

  final int state;
  final int error;
  final int progressPct;
  final int bytesReceived;

  static BleOtaStatusFrame? parse(List<int> raw) {
    if (raw.length < 8) return null;
    final bytesReceived = (raw[4] << 24) | (raw[5] << 16) | (raw[6] << 8) | raw[7];
    return BleOtaStatusFrame(
      state: raw[0],
      error: raw[1],
      progressPct: raw[2],
      bytesReceived: bytesReceived,
    );
  }

  static List<int> encode({
    required int state,
    int error = BleOtaError.none,
    int progressPct = 0,
    int bytesReceived = 0,
  }) {
    return [
      state & 0xff,
      error & 0xff,
      progressPct.clamp(0, 100) & 0xff,
      0,
      (bytesReceived >> 24) & 0xff,
      (bytesReceived >> 16) & 0xff,
      (bytesReceived >> 8) & 0xff,
      bytesReceived & 0xff,
    ];
  }
}

/// Builds the 40-byte `OTA_START` write payload for `ota_control`.
List<int> buildBleOtaStartPayload({
  required BadgeFirmwareImage image,
}) {
  final size = image.size;
  final sha = image.sha256Digest;
  final v = image.targetVersion;
  return [
    BleOtaCommand.start,
    (size >> 24) & 0xff,
    (size >> 16) & 0xff,
    (size >> 8) & 0xff,
    size & 0xff,
    ...sha,
    v.major & 0xff,
    v.minor & 0xff,
    v.patch & 0xff,
  ];
}

int bleOtaChunkSizeForMtu(int mtu) {
  final chunk = mtu - 3;
  return chunk < 20 ? 20 : chunk;
}

String bleOtaErrorMessage(int errorCode) {
  return switch (errorCode) {
    BleOtaError.none => 'Unbekannter Fehler',
    BleOtaError.busy => 'Gerät ist beschäftigt',
    BleOtaError.badSize => 'Ungültige Firmware-Größe',
    BleOtaError.flash => 'Flash-Schreibfehler',
    BleOtaError.sha => 'SHA-256 stimmt nicht überein',
    BleOtaError.version => 'Firmware-Version ist nicht neuer',
    BleOtaError.abort => 'Update abgebrochen',
    BleOtaError.timeout => 'Zeitüberschreitung',
    _ => 'OTA-Fehler ($errorCode)',
  };
}

/// Performs Badge BLE OTA over Luftdaten GATT (`ota_control` / `ota_data`).
class BleOtaClient {
  BleOtaClient({
    BleGattTransport? transport,
    BleController? bleController,
  })  : _transport = transport ?? FlutterReactiveBleTransport.instance,
        _bleController = bleController ?? BleController();

  final BleGattTransport _transport;
  final BleController _bleController;

  static const Duration _chunkDelay = Duration(milliseconds: 15);
  static const Duration _rebootWait = Duration(seconds: 3);
  static const int _preferredMtu = 517;

  Future<BleOtaResult> performUpdate({
    required BleDevice device,
    required BadgeFirmwareImage image,
    void Function(BleOtaProgress progress)? onProgress,
    Future<bool> Function()? shouldCancel,
  }) async {
    if (device.model != LDDeviceModel.badge) {
      return BleOtaResult.failure('Nur für Air Badge verfügbar.');
    }
    if (device.state != BleDeviceState.connected || device.bleId == null) {
      return BleOtaResult.failure('Bluetooth nicht verbunden.');
    }
    if (!BadgeFirmwareImage.isUpgradeFrom(
      current: device.firmwareVersion,
      target: image.targetVersion,
    )) {
      return BleOtaResult.failure('Die gewählte Version ist nicht neuer als die installierte.');
    }

    final deviceId = device.bleId!;
    StreamSubscription<List<int>>? notifySub;
    var cancelled = false;

    try {
      final mtu = await _transport.requestMtu(deviceId: deviceId, mtu: _preferredMtu);
      final chunkSize = bleOtaChunkSizeForMtu(mtu);
      logger.d('Badge OTA: mtu=$mtu chunkSize=$chunkSize bytes=${image.size}');

      final notifyStream = _transport.subscribeCharacteristic(
        deviceId: deviceId,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.otaControl,
      );

      final completer = Completer<BleOtaStatusFrame?>();
      BleOtaStatusFrame? lastFrame;

      notifySub = notifyStream.listen((raw) {
        final frame = BleOtaStatusFrame.parse(raw);
        if (frame == null) return;
        lastFrame = frame;
        onProgress?.call(BleOtaProgress(
          state: frame.state,
          error: frame.error,
          progressPct: frame.progressPct,
          bytesReceived: frame.bytesReceived,
          totalBytes: image.size,
        ));
        if (frame.state == BleOtaState.rebooting ||
            (frame.state == BleOtaState.error && frame.error != BleOtaError.none)) {
          if (!completer.isCompleted) completer.complete(frame);
        }
      });

      await _transport.writeCharacteristicWithResponse(
        deviceId: deviceId,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.otaControl,
        value: buildBleOtaStartPayload(image: image),
      );

      await _waitForState(
        notifyStream: notifyStream,
        accept: (frame) =>
            frame.state == BleOtaState.ready || frame.state == BleOtaState.receiving,
        reject: (frame) =>
            frame.state == BleOtaState.error && frame.error != BleOtaError.none,
        timeout: const Duration(seconds: 15),
        onProgress: onProgress,
        totalBytes: image.size,
      );

      var offset = 0;
      while (offset < image.bytes.length) {
        if (await _cancelRequested(shouldCancel)) {
          cancelled = true;
          await _sendAbort(deviceId);
          return BleOtaResult.cancelledResult();
        }

        final end = (offset + chunkSize > image.bytes.length)
            ? image.bytes.length
            : offset + chunkSize;
        await _transport.writeCharacteristicWithoutResponse(
          deviceId: deviceId,
          serviceId: BleGattUuids.service,
          characteristicId: BleGattUuids.otaData,
          value: image.bytes.sublist(offset, end),
        );
        offset = end;
        await Future<void>.delayed(_chunkDelay);
      }

      await _transport.writeCharacteristicWithResponse(
        deviceId: deviceId,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.otaControl,
        value: const [BleOtaCommand.finish],
      );

      final finishFrame = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => lastFrame,
      );

      if (finishFrame == null) {
        return BleOtaResult.failure('Keine OTA-Antwort vom Gerät.');
      }
      if (finishFrame.state == BleOtaState.error && finishFrame.error != BleOtaError.none) {
        return BleOtaResult.failure(bleOtaErrorMessage(finishFrame.error));
      }
      if (finishFrame.state != BleOtaState.rebooting) {
        return BleOtaResult.failure('Gerät hat nicht neu gestartet (Status ${finishFrame.state}).');
      }

      if (!MockBleDevices.canUseMockBle(device)) {
        device.disconnect();
      }
      await Future<void>.delayed(_rebootWait);

      if (MockBleDevices.canUseMockBle(device)) {
        await _bleController.refreshDeviceInfo(device);
      } else {
        final reconnected = await device.connect(showNoticesOnConnect: false);
        if (!reconnected) {
          return BleOtaResult.failure('Neuverbindung nach Update fehlgeschlagen.');
        }
        await _bleController.refreshDeviceInfo(device);
      }

      final confirmed = device.firmwareVersion;
      if (confirmed == null || confirmed.isUnsetPlaceholder) {
        return BleOtaResult.failure('Firmware-Version nach Update nicht lesbar.');
      }
      if (confirmed.isOlderThan(image.targetVersion)) {
        return BleOtaResult.failure(
          'Update unvollständig (Gerät meldet $confirmed, erwartet ${image.targetVersion}).',
        );
      }

      return BleOtaResult.success(confirmed);
    } on TimeoutException {
      if (cancelled) return BleOtaResult.cancelledResult();
      return BleOtaResult.failure('Zeitüberschreitung beim Firmware-Update.');
    } catch (e, st) {
      logger.d('Badge OTA failed: $e $st');
      if (cancelled) return BleOtaResult.cancelledResult();
      return BleOtaResult.failure('Firmware-Update fehlgeschlagen: $e');
    } finally {
      await notifySub?.cancel();
      if (MockBleDevices.canUseMockBle(device)) {
        MockBleGatt.closeOtaSubscription(device);
      }
    }
  }

  Future<void> _sendAbort(String deviceId) async {
    try {
      await _transport.writeCharacteristicWithResponse(
        deviceId: deviceId,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.otaControl,
        value: const [BleOtaCommand.abort],
      );
    } catch (_) {}
  }

  Future<bool> _cancelRequested(Future<bool> Function()? shouldCancel) async {
    if (shouldCancel == null) return false;
    return shouldCancel();
  }

  Future<BleOtaStatusFrame> _waitForState({
    required Stream<List<int>> notifyStream,
    required bool Function(BleOtaStatusFrame frame) accept,
    required bool Function(BleOtaStatusFrame frame) reject,
    required Duration timeout,
    void Function(BleOtaProgress progress)? onProgress,
    required int totalBytes,
  }) async {
    final frame = await notifyStream
        .map(BleOtaStatusFrame.parse)
        .where((f) => f != null)
        .cast<BleOtaStatusFrame>()
        .firstWhere(
          (f) => accept(f) || reject(f),
          orElse: () => throw TimeoutException('OTA status timeout'),
        )
        .timeout(timeout);

    onProgress?.call(BleOtaProgress(
      state: frame.state,
      error: frame.error,
      progressPct: frame.progressPct,
      bytesReceived: frame.bytesReceived,
      totalBytes: totalBytes,
    ));

    if (reject(frame)) {
      throw StateError(bleOtaErrorMessage(frame.error));
    }
    return frame;
  }
}
