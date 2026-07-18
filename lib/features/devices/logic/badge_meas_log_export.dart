import 'dart:async';
import 'dart:typed_data';

import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/flutter_reactive_ble_transport.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';

abstract final class BadgeMeasLogCommand {
  static const int logStatus = 0x01;
  static const int startExport = 0x02;
  static const int logAbort = 0x03;
  static const int logErase = 0x04;
}

abstract final class BadgeMeasLogState {
  static const int idle = 0;
  static const int exporting = 1;
  static const int done = 2;
  static const int error = 3;
}

abstract final class BadgeMeasLogError {
  static const int none = 0;
  static const int busyMeasuring = 1;
  static const int noFlash = 2;
  static const int empty = 3;
  static const int abort = 4;
}

class BadgeMeasLogStatusFrame {
  const BadgeMeasLogStatusFrame({
    required this.state,
    required this.error,
    required this.recordCount,
    required this.totalBytes,
    required this.offset,
  });

  final int state;
  final int error;
  final int recordCount;
  final int totalBytes;
  final int offset;

  bool get hasRecords => recordCount > 0;

  static BadgeMeasLogStatusFrame? parse(List<int> raw) {
    if (raw.length < 14) return null;
    return BadgeMeasLogStatusFrame(
      state: raw[0],
      error: raw[1],
      recordCount: _u32le(raw, 2),
      totalBytes: _u32le(raw, 6),
      offset: _u32le(raw, 10),
    );
  }

  static List<int> encode({
    required int state,
    int error = BadgeMeasLogError.none,
    int recordCount = 0,
    int totalBytes = 0,
    int offset = 0,
  }) {
    return [
      state & 0xff,
      error & 0xff,
      ..._u32leBytes(recordCount),
      ..._u32leBytes(totalBytes),
      ..._u32leBytes(offset),
    ];
  }
}

class BadgeMeasLogPeekInfo {
  const BadgeMeasLogPeekInfo({
    required this.recordCount,
    required this.totalBytes,
  });

  final int recordCount;
  final int totalBytes;

  bool get logNonEmpty => recordCount > 0;
}

class BadgeMeasLogExportResult {
  const BadgeMeasLogExportResult._({
    required this.ok,
    this.bytes,
    this.errorMessage,
    this.cancelled = false,
  });

  final bool ok;
  final Uint8List? bytes;
  final String? errorMessage;
  final bool cancelled;

  factory BadgeMeasLogExportResult.success(Uint8List bytes) =>
      BadgeMeasLogExportResult._(ok: true, bytes: bytes);

  factory BadgeMeasLogExportResult.failure(String message) =>
      BadgeMeasLogExportResult._(ok: false, errorMessage: message);

  factory BadgeMeasLogExportResult.cancelledResult() =>
      const BadgeMeasLogExportResult._(
        ok: false,
        cancelled: true,
        errorMessage: 'Abgebrochen',
      );
}

class BadgeMeasLogExportProgress {
  const BadgeMeasLogExportProgress({
    required this.bytesReceived,
    required this.totalBytes,
    required this.state,
  });

  final int bytesReceived;
  final int totalBytes;
  final int state;

  int get progressPct =>
      totalBytes <= 0 ? 0 : ((bytesReceived * 100) / totalBytes).floor().clamp(0, 100);
}

String badgeMeasLogErrorMessage(int errorCode) {
  return switch (errorCode) {
    BadgeMeasLogError.none => 'Unbekannter Fehler',
    BadgeMeasLogError.busyMeasuring => 'Messmodus ist noch aktiv',
    BadgeMeasLogError.noFlash => 'Externer Speicher nicht verfügbar',
    BadgeMeasLogError.empty => 'Kein Messprotokoll vorhanden',
    BadgeMeasLogError.abort => 'Export abgebrochen',
    _ => 'Log-Fehler ($errorCode)',
  };
}

class BadgeMeasLogExportClient {
  BadgeMeasLogExportClient({BleGattTransport? transport})
      : _transport = transport ?? FlutterReactiveBleTransport.instance;

  final BleGattTransport _transport;

  static const int _preferredMtu = 517;

  Future<BadgeMeasLogPeekInfo?> peekStatus(BleDevice device) async {
    if (device.model != LDDeviceModel.badge) return null;
    if (device.state != BleDeviceState.connected || device.bleId == null) return null;
    if (device.isMeasLoggingActive) return null;

    try {
      final frame = await _requestStatus(device.bleId!);
      if (frame == null) return null;
      if (frame.state == BadgeMeasLogState.error && frame.error != BadgeMeasLogError.none) {
        return null;
      }
      return BadgeMeasLogPeekInfo(
        recordCount: frame.recordCount,
        totalBytes: frame.totalBytes,
      );
    } catch (e, st) {
      logger.d('peekBadgeMeasLog failed: $e $st');
      return null;
    }
  }

  Future<BadgeMeasLogExportResult> export({
    required BleDevice device,
    void Function(BadgeMeasLogExportProgress progress)? onProgress,
    Future<bool> Function()? shouldCancel,
  }) async {
    if (device.model != LDDeviceModel.badge) {
      return BadgeMeasLogExportResult.failure('Nur für Air Badge verfügbar.');
    }
    if (device.state != BleDeviceState.connected || device.bleId == null) {
      return BadgeMeasLogExportResult.failure('Bluetooth nicht verbunden.');
    }
    if (device.isMeasLoggingActive) {
      return BadgeMeasLogExportResult.failure('Messmodus ist noch aktiv.');
    }

    final deviceId = device.bleId!;
    StreamSubscription<List<int>>? controlSub;
    StreamSubscription<List<int>>? dataSub;
    var cancelled = false;

    try {
      await _transport.requestMtu(deviceId: deviceId, mtu: _preferredMtu);

      final statusFrame = await _requestStatus(deviceId);
      if (statusFrame == null) {
        return BadgeMeasLogExportResult.failure('Log-Status nicht lesbar.');
      }
      if (statusFrame.state == BadgeMeasLogState.error &&
          statusFrame.error != BadgeMeasLogError.none) {
        return BadgeMeasLogExportResult.failure(badgeMeasLogErrorMessage(statusFrame.error));
      }
      if (!statusFrame.hasRecords) {
        return BadgeMeasLogExportResult.failure('Kein Messprotokoll vorhanden.');
      }

      final totalBytes = statusFrame.totalBytes;
      final buffer = BytesBuilder(copy: false);
      final completer = Completer<BadgeMeasLogStatusFrame?>();
      BadgeMeasLogStatusFrame? lastControl;

      controlSub = _transport
          .subscribeCharacteristic(
            deviceId: deviceId,
            serviceId: BleGattUuids.service,
            characteristicId: BleGattUuids.logControl,
          )
          .listen((raw) {
        final frame = BadgeMeasLogStatusFrame.parse(raw);
        if (frame == null) return;
        lastControl = frame;
        onProgress?.call(BadgeMeasLogExportProgress(
          bytesReceived: frame.offset,
          totalBytes: totalBytes,
          state: frame.state,
        ));
        if (frame.state == BadgeMeasLogState.done ||
            (frame.state == BadgeMeasLogState.error && frame.error != BadgeMeasLogError.none)) {
          if (!completer.isCompleted) completer.complete(frame);
        }
      });

      dataSub = _transport
          .subscribeCharacteristic(
            deviceId: deviceId,
            serviceId: BleGattUuids.service,
            characteristicId: BleGattUuids.logData,
          )
          .listen((raw) {
        if (raw.length <= 2) return;
        buffer.add(raw.sublist(2));
      });

      await _transport.writeCharacteristicWithResponse(
        deviceId: deviceId,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.logControl,
        value: const [BadgeMeasLogCommand.startExport],
      );

      final doneFrame = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => lastControl,
      );

      if (await _cancelRequested(shouldCancel)) {
        cancelled = true;
        await _sendAbort(deviceId);
        return BadgeMeasLogExportResult.cancelledResult();
      }

      if (doneFrame == null) {
        return BadgeMeasLogExportResult.failure('Keine Log-Antwort vom Gerät.');
      }
      if (doneFrame.state == BadgeMeasLogState.error && doneFrame.error != BadgeMeasLogError.none) {
        return BadgeMeasLogExportResult.failure(badgeMeasLogErrorMessage(doneFrame.error));
      }
      if (doneFrame.state != BadgeMeasLogState.done) {
        return BadgeMeasLogExportResult.failure('Export nicht abgeschlossen (Status ${doneFrame.state}).');
      }

      final bytes = buffer.toBytes();
      if (bytes.length != totalBytes) {
        return BadgeMeasLogExportResult.failure(
          'Unvollständiger Export (${bytes.length} von $totalBytes Bytes).',
        );
      }

      return BadgeMeasLogExportResult.success(Uint8List.fromList(bytes));
    } on TimeoutException {
      if (cancelled) return BadgeMeasLogExportResult.cancelledResult();
      return BadgeMeasLogExportResult.failure('Zeitüberschreitung beim Log-Export.');
    } catch (e, st) {
      logger.d('Badge meas log export failed: $e $st');
      if (cancelled) return BadgeMeasLogExportResult.cancelledResult();
      return BadgeMeasLogExportResult.failure('Log-Export fehlgeschlagen: $e');
    } finally {
      await controlSub?.cancel();
      await dataSub?.cancel();
      if (MockBleDevices.canUseMockBle(device)) {
        MockBleGatt.closeMeasLogSubscriptions(device);
      }
    }
  }

  Future<bool> eraseLog(BleDevice device) async {
    if (device.model != LDDeviceModel.badge) return false;
    if (device.state != BleDeviceState.connected || device.bleId == null) return false;
    try {
      await _transport.writeCharacteristicWithResponse(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.logControl,
        value: const [BadgeMeasLogCommand.logErase],
      );
      return true;
    } catch (e, st) {
      logger.d('Badge meas log erase failed: $e $st');
      return false;
    }
  }

  Future<BadgeMeasLogStatusFrame?> _requestStatus(String deviceId) async {
    await _transport.writeCharacteristicWithResponse(
      deviceId: deviceId,
      serviceId: BleGattUuids.service,
      characteristicId: BleGattUuids.logControl,
      value: const [BadgeMeasLogCommand.logStatus],
    );

    final raw = await _transport.readCharacteristic(
      deviceId: deviceId,
      serviceId: BleGattUuids.service,
      characteristicId: BleGattUuids.logControl,
    );
    return BadgeMeasLogStatusFrame.parse(raw);
  }

  Future<void> _sendAbort(String deviceId) async {
    try {
      await _transport.writeCharacteristicWithResponse(
        deviceId: deviceId,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.logControl,
        value: const [BadgeMeasLogCommand.logAbort],
      );
    } catch (_) {}
  }

  Future<bool> _cancelRequested(Future<bool> Function()? shouldCancel) async {
    if (shouldCancel == null) return false;
    return shouldCancel();
  }
}

int _u32le(List<int> raw, int offset) {
  return raw[offset] |
      (raw[offset + 1] << 8) |
      (raw[offset + 2] << 16) |
      (raw[offset + 3] << 24);
}

List<int> _u32leBytes(int value) {
  return [
    value & 0xff,
    (value >> 8) & 0xff,
    (value >> 16) & 0xff,
    (value >> 24) & 0xff,
  ];
}
