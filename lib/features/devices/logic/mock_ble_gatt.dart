import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_firmware_image.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/badge_meas_log_export.dart';
import 'package:luftdaten.at/features/devices/logic/ble_ota.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt_codec.dart';

class MockBleMeasLogSession {
  MockBleMeasLogSession({Uint8List? initialLog}) : _logBytes = initialLog ?? Uint8List(0);

  Uint8List _logBytes;
  bool _exporting = false;
  int _exportOffset = 0;
  int _seq = 0;

  Uint8List get logBytes => _logBytes;

  bool get hasLog => _logBytes.isNotEmpty;

  BadgeMeasLogStatusFrame statusFrame({
    int? state,
    int error = BadgeMeasLogError.none,
  }) {
    if (_logBytes.length < 64) {
      return BadgeMeasLogStatusFrame(
        state: state ?? BadgeMeasLogState.idle,
        error: error,
        recordCount: 0,
        totalBytes: 0,
        offset: _exportOffset,
      );
    }
    final recordCount = _u32le(_logBytes, 6);
    final totalBytes = 64 + recordCount * (_logBytes[10] | (_logBytes[11] << 8));
    final effectiveState = state ??
        (_exporting && _exportOffset < totalBytes
            ? BadgeMeasLogState.exporting
            : BadgeMeasLogState.idle);
    return BadgeMeasLogStatusFrame(
      state: effectiveState,
      error: error,
      recordCount: recordCount,
      totalBytes: totalBytes,
      offset: _exportOffset,
    );
  }

  BadgeMeasLogStatusFrame? handleControlWrite(List<int> value, {required bool measuring}) {
    if (value.isEmpty) return null;
    switch (value.first) {
      case BadgeMeasLogCommand.logStatus:
        return statusFrame();
      case BadgeMeasLogCommand.startExport:
        if (measuring) {
          return const BadgeMeasLogStatusFrame(
            state: BadgeMeasLogState.error,
            error: BadgeMeasLogError.busyMeasuring,
            recordCount: 0,
            totalBytes: 0,
            offset: 0,
          );
        }
        if (!hasLog) {
          return const BadgeMeasLogStatusFrame(
            state: BadgeMeasLogState.error,
            error: BadgeMeasLogError.empty,
            recordCount: 0,
            totalBytes: 0,
            offset: 0,
          );
        }
        _exporting = true;
        _exportOffset = 0;
        _seq = 0;
        return statusFrame(state: BadgeMeasLogState.exporting);
      case BadgeMeasLogCommand.logAbort:
        _exporting = false;
        _exportOffset = 0;
        return statusFrame(state: BadgeMeasLogState.error, error: BadgeMeasLogError.abort);
      case BadgeMeasLogCommand.logErase:
        _logBytes = Uint8List(0);
        _exporting = false;
        _exportOffset = 0;
        return statusFrame();
      default:
        return null;
    }
  }

  List<List<int>>? drainExportChunks({int chunkPayload = 20}) {
    if (!_exporting || !hasLog) return null;
    final total = statusFrame().totalBytes;
    if (_exportOffset >= total) {
      _exporting = false;
      return null;
    }
    final chunks = <List<int>>[];
    while (_exportOffset < total) {
      final end = (_exportOffset + chunkPayload > total) ? total : _exportOffset + chunkPayload;
      final payload = _logBytes.sublist(_exportOffset, end);
      chunks.add([_seq & 0xff, (_seq >> 8) & 0xff, ...payload]);
      _seq++;
      _exportOffset = end;
    }
    return chunks;
  }

  static int _u32le(Uint8List raw, int offset) {
    return raw[offset] |
        (raw[offset + 1] << 8) |
        (raw[offset + 2] << 16) |
        (raw[offset + 3] << 24);
  }
}

class MockBleOtaSession {
  MockBleOtaSession();

  bool active = false;
  int expectedSize = 0;
  List<int> expectedSha = const [];
  FirmwareVersion? targetVersion;
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  int _lastProgressPct = -1;

  void reset() {
    active = false;
    expectedSize = 0;
    expectedSha = const [];
    targetVersion = null;
    _buffer.clear();
    _lastProgressPct = -1;
  }

  int get receivedBytes => _buffer.length;

  BleOtaStatusFrame? handleControlWrite(List<int> value) {
    if (value.isEmpty) return null;
    switch (value.first) {
      case BleOtaCommand.start:
        return _handleStart(value);
      case BleOtaCommand.abort:
        reset();
        return BleOtaStatusFrame(
          state: BleOtaState.error,
          error: BleOtaError.abort,
          progressPct: 0,
          bytesReceived: 0,
        );
      case BleOtaCommand.finish:
        return _handleFinish();
      default:
        return null;
    }
  }

  BleOtaStatusFrame? handleDataWrite(List<int> value) {
    if (!active) return null;
    _buffer.add(value);
    final pct = expectedSize <= 0
        ? 0
        : ((receivedBytes * 100) / expectedSize).floor().clamp(0, 100);
    if (pct == _lastProgressPct) return null;
    _lastProgressPct = pct;
    return BleOtaStatusFrame(
      state: BleOtaState.receiving,
      error: BleOtaError.none,
      progressPct: pct,
      bytesReceived: receivedBytes,
    );
  }

  BleOtaStatusFrame? _handleStart(List<int> value) {
    reset();
    if (value.length < 40) {
      return const BleOtaStatusFrame(
        state: BleOtaState.error,
        error: BleOtaError.badSize,
        progressPct: 0,
        bytesReceived: 0,
      );
    }

    expectedSize = (value[1] << 24) | (value[2] << 16) | (value[3] << 8) | value[4];
    expectedSha = value.sublist(5, 37);
    targetVersion = FirmwareVersion(value[37], value[38], value[39]);
    active = true;

    return BleOtaStatusFrame(
      state: BleOtaState.ready,
      error: BleOtaError.none,
      progressPct: 0,
      bytesReceived: 0,
    );
  }

  BleOtaStatusFrame? _handleFinish() {
    if (!active) {
      return const BleOtaStatusFrame(
        state: BleOtaState.error,
        error: BleOtaError.busy,
        progressPct: 0,
        bytesReceived: 0,
      );
    }

    final bytes = _buffer.toBytes();
    if (bytes.length != expectedSize) {
      reset();
      return BleOtaStatusFrame(
        state: BleOtaState.error,
        error: BleOtaError.badSize,
        progressPct: 0,
        bytesReceived: bytes.length,
      );
    }

    final digest = sha256.convert(bytes).bytes;
    if (!_listEquals(digest, expectedSha)) {
      reset();
      return const BleOtaStatusFrame(
        state: BleOtaState.error,
        error: BleOtaError.sha,
        progressPct: 0,
        bytesReceived: 0,
      );
    }

    return BleOtaStatusFrame(
      state: BleOtaState.verifying,
      error: BleOtaError.none,
      progressPct: 100,
      bytesReceived: bytes.length,
    );
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class MockBleGattState {
  MockBleGattState({
    required this.device,
    required this.batteryPct,
    required this.operationalFlags,
    required this.airStationConfigTlv,
    required this.sensorValues,
    Uint8List? measLogBytes,
  }) : measLog = MockBleMeasLogSession(initialLog: measLogBytes);

  final BleDevice device;
  double batteryPct;
  int operationalFlags;
  List<int> airStationConfigTlv;
  List<int> sensorValues;
  AirStationConfig? airStationConfig;
  int _telemetryTick = 0;
  final MockBleOtaSession ota = MockBleOtaSession();
  final MockBleMeasLogSession measLog;

  void refreshTelemetry() {
    sensorValues = MockBleGattCodec.encodeSensorValuesForDevice(
      device,
      timeSeconds: _telemetryTick * 30.0,
    );
  }

  void refreshBattery() {
    batteryPct = (batteryPct + (Random().nextDouble() * 2 - 1)).clamp(20.0, 95.0);
  }

  List<int> deviceInfoBytes() => MockBleGattCodec.encodeDeviceInfoJson(device);

  List<int> sensorInfoBytes() => MockBleGattCodec.encodeSensorInfo(device);

  List<int> deviceStatusBytes({bool refreshBatteryOnRead = false}) {
    if (refreshBatteryOnRead) refreshBattery();
    return MockBleGattCodec.encodeDeviceStatus(
      batteryPct: batteryPct,
      operationalFlags: operationalFlags,
    );
  }

  List<int> airStationConfigurationBytes() {
    if (device.model != LDDeviceModel.station) return const [0];
    return airStationConfigTlv;
  }

  List<int> otaControlBytes() {
    return BleOtaStatusFrame.encode(
      state: ota.active ? BleOtaState.receiving : BleOtaState.idle,
      progressPct: ota.expectedSize <= 0
          ? 0
          : ((ota.receivedBytes * 100) / ota.expectedSize).floor().clamp(0, 100),
      bytesReceived: ota.receivedBytes,
    );
  }

  List<int> measLogControlBytes() {
    final frame = measLog.statusFrame();
    return BadgeMeasLogStatusFrame.encode(
      state: frame.state,
      error: frame.error,
      recordCount: frame.recordCount,
      totalBytes: frame.totalBytes,
      offset: frame.offset,
    );
  }

  BadgeMeasLogStatusFrame? handleMeasLogControlWrite(List<int> value) {
    return measLog.handleControlWrite(value, measuring: device.isMeasLoggingActive);
  }

  BleOtaStatusFrame? handleOtaControlWrite(List<int> value) {
    final frame = ota.handleControlWrite(value);
    if (frame == null) return null;

    if (value.first == BleOtaCommand.start &&
        frame.state == BleOtaState.ready &&
        ota.targetVersion != null) {
      final current = device.firmwareVersion;
      if (!BadgeFirmwareImage.isUpgradeFrom(
        current: current,
        target: ota.targetVersion!,
      )) {
        ota.reset();
        return const BleOtaStatusFrame(
          state: BleOtaState.error,
          error: BleOtaError.version,
          progressPct: 0,
          bytesReceived: 0,
        );
      }
    }

    if (value.first == BleOtaCommand.finish && frame.state == BleOtaState.verifying) {
      device.firmwareVersion = ota.targetVersion;
      ota.reset();
      return const BleOtaStatusFrame(
        state: BleOtaState.rebooting,
        error: BleOtaError.none,
        progressPct: 100,
        bytesReceived: 0,
      );
    }

    return frame;
  }

  void handleCommand(List<int> value) {
    if (value.isEmpty) return;
    switch (value.first) {
      case MockBleGattCodec.cmdReadSensorData:
        refreshTelemetry();
      case MockBleGattCodec.cmdReadSensorDataAndBattery:
        refreshTelemetry();
        refreshBattery();
      case MockBleGattCodec.cmdSetAirStationConfiguration:
        _mergeAirStationConfiguration(value);
      default:
        break;
    }
  }

  void _mergeAirStationConfiguration(List<int> payload) {
    if (device.model != LDDeviceModel.station) return;
    if (payload.isEmpty || payload.first != MockBleGattCodec.cmdSetAirStationConfiguration) {
      return;
    }
    final incoming = payload.sublist(1);
    airStationConfigTlv =
        MockBleGattCodec.mergeTlvRecords(airStationConfigTlv, incoming);
    airStationConfig = AirStationConfig.parseFromBytes(
      device.chipIdForApi,
      airStationConfigTlv,
    );
    airStationConfigTlv =
        MockBleGattCodec.encodeAirStationConfigReadBack(airStationConfig!);
  }
}

/// In-memory GATT server for debug mock BLE devices.
abstract final class MockBleGatt {
  static final Map<String, MockBleGattState> _states = {};
  static final Map<String, StreamController<List<int>>> _otaNotifyControllers = {};
  static final Map<String, StreamController<List<int>>> _measLogControlControllers = {};
  static final Map<String, StreamController<List<int>>> _measLogDataControllers = {};

  static MockBleGattState initForDevice(BleDevice device) {
    final id = device.bleId ?? 'mock:${device.bleName}';
    device.bleId ??= id;

    final initialConfig = device.model == LDDeviceModel.station
        ? AirStationConfig.defaultConfig(device.chipIdForApi)
        : null;

    final airStationConfigTlv = initialConfig == null
        ? <int>[]
        : MockBleGattCodec.encodeAirStationConfigReadBack(initialConfig);

    final state = MockBleGattState(
      device: device,
      batteryPct: 78,
      operationalFlags: MockBleGattCodec.defaultOperationalFlags(device.model),
      airStationConfigTlv: airStationConfigTlv,
      sensorValues: MockBleGattCodec.encodeSensorValuesForDevice(device),
      measLogBytes: device.model == LDDeviceModel.badge
          ? MockBleGattCodec.encodeBadgeMeasLogBlob()
          : null,
    )..airStationConfig = initialConfig;

    _states[id] = state;
    return state;
  }

  static MockBleGattState stateFor(BleDevice device) {
    final id = device.bleId;
    if (id == null) return initForDevice(device);
    return _states.putIfAbsent(id, () => initForDevice(device));
  }

  static void removeDevice(BleDevice device) {
    final id = device.bleId;
    if (id != null) {
      _states.remove(id);
      closeOtaSubscription(device);
      closeMeasLogSubscriptions(device);
    }
  }

  static Stream<List<int>> subscribeOtaControl(BleDevice device) {
    final id = device.bleId ?? initForDevice(device).device.bleId!;
    final controller = _otaNotifyControllers.putIfAbsent(
      id,
      () => StreamController<List<int>>.broadcast(),
    );
    return controller.stream;
  }

  static void closeOtaSubscription(BleDevice device) {
    final id = device.bleId;
    if (id == null) return;
    _otaNotifyControllers.remove(id)?.close();
  }

  static void _emitOtaNotify(BleDevice device, BleOtaStatusFrame frame) {
    final id = device.bleId;
    if (id == null) return;
    _otaNotifyControllers[id]?.add(BleOtaStatusFrame.encode(
      state: frame.state,
      error: frame.error,
      progressPct: frame.progressPct,
      bytesReceived: frame.bytesReceived,
    ));
  }

  static Stream<List<int>> subscribeMeasLogControl(BleDevice device) {
    final id = device.bleId ?? initForDevice(device).device.bleId!;
    final controller = _measLogControlControllers.putIfAbsent(
      id,
      () => StreamController<List<int>>.broadcast(),
    );
    return controller.stream;
  }

  static Stream<List<int>> subscribeMeasLogData(BleDevice device) {
    final id = device.bleId ?? initForDevice(device).device.bleId!;
    final controller = _measLogDataControllers.putIfAbsent(
      id,
      () => StreamController<List<int>>.broadcast(),
    );
    return controller.stream;
  }

  static void closeMeasLogSubscriptions(BleDevice device) {
    final id = device.bleId;
    if (id == null) return;
    _measLogControlControllers.remove(id)?.close();
    _measLogDataControllers.remove(id)?.close();
  }

  static void _emitMeasLogControlNotify(BleDevice device, BadgeMeasLogStatusFrame frame) {
    final id = device.bleId;
    if (id == null) return;
    _measLogControlControllers[id]?.add(BadgeMeasLogStatusFrame.encode(
      state: frame.state,
      error: frame.error,
      recordCount: frame.recordCount,
      totalBytes: frame.totalBytes,
      offset: frame.offset,
    ));
  }

  static void _emitMeasLogDataNotify(BleDevice device, List<int> chunk) {
    final id = device.bleId;
    if (id == null) return;
    _measLogDataControllers[id]?.add(chunk);
  }

  static Future<void> _runMeasLogExport(BleDevice device) async {
    final state = stateFor(device);
    while (state.measLog.statusFrame().state == BadgeMeasLogState.exporting) {
      final chunks = state.measLog.drainExportChunks();
      if (chunks == null || chunks.isEmpty) break;
      for (final chunk in chunks) {
        _emitMeasLogDataNotify(device, chunk);
      }
      _emitMeasLogControlNotify(
        device,
        state.measLog.statusFrame(state: BadgeMeasLogState.exporting),
      );
      await Future<void>.delayed(Duration.zero);
    }

    final status = state.measLog.statusFrame();
    _emitMeasLogControlNotify(
      device,
      BadgeMeasLogStatusFrame(
        state: BadgeMeasLogState.done,
        error: BadgeMeasLogError.none,
        recordCount: status.recordCount,
        totalBytes: status.totalBytes,
        offset: status.totalBytes,
      ),
    );
  }

  static void writeMeasLogControl(BleDevice device, List<int> value) {
    final state = stateFor(device);
    final frame = state.handleMeasLogControlWrite(value);
    if (frame == null) return;
    _emitMeasLogControlNotify(device, frame);
    if (value.first == BadgeMeasLogCommand.startExport &&
        frame.state == BadgeMeasLogState.exporting) {
      unawaited(_runMeasLogExport(device));
    }
  }

  static List<int> readCharacteristic(BleDevice device, Uuid characteristicId) {
    final state = stateFor(device);
    if (characteristicId == BleGattUuids.deviceInfo) {
      return state.deviceInfoBytes();
    }
    if (characteristicId == BleGattUuids.sensorInfo) {
      return state.sensorInfoBytes();
    }
    if (characteristicId == BleGattUuids.deviceStatus) {
      return state.deviceStatusBytes();
    }
    if (characteristicId == BleGattUuids.sensorValues) {
      return state.sensorValues;
    }
    if (characteristicId == BleGattUuids.airStationConfiguration) {
      return state.airStationConfigurationBytes();
    }
    if (characteristicId == BleGattUuids.otaControl) {
      return state.otaControlBytes();
    }
    if (characteristicId == BleGattUuids.logControl) {
      return state.measLogControlBytes();
    }
    return const [];
  }

  static void writeCommand(BleDevice device, List<int> value) {
    stateFor(device).handleCommand(value);
  }

  static void writeOtaControl(BleDevice device, List<int> value) {
    final state = stateFor(device);
    final frame = state.handleOtaControlWrite(value);
    if (frame != null) {
      _emitOtaNotify(device, frame);
      if (value.first == BleOtaCommand.start && frame.state == BleOtaState.ready) {
        _emitOtaNotify(
          device,
          BleOtaStatusFrame(
            state: BleOtaState.receiving,
            error: BleOtaError.none,
            progressPct: 0,
            bytesReceived: 0,
          ),
        );
      }
    }
  }

  static void writeOtaData(BleDevice device, List<int> value) {
    final state = stateFor(device);
    final frame = state.ota.handleDataWrite(value);
    if (frame != null) {
      _emitOtaNotify(device, frame);
    }
  }
}

class MockBleGattTransport implements BleGattTransport {
  MockBleGattTransport._();

  static final MockBleGattTransport instance = MockBleGattTransport._();

  @override
  Future<List<int>> readCharacteristic({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
  }) async {
    final device = _deviceForId(deviceId);
    if (device == null) return const [];
    return MockBleGatt.readCharacteristic(device, characteristicId);
  }

  @override
  Future<void> writeCharacteristicWithoutResponse({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
    required List<int> value,
  }) async {
    final device = _deviceForId(deviceId);
    if (device == null) return;
    if (characteristicId == BleGattUuids.command) {
      MockBleGatt.writeCommand(device, value);
    } else if (characteristicId == BleGattUuids.otaData) {
      MockBleGatt.writeOtaData(device, value);
    }
  }

  @override
  Future<void> writeCharacteristicWithResponse({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
    required List<int> value,
  }) async {
    final device = _deviceForId(deviceId);
    if (device == null) return;
    if (characteristicId == BleGattUuids.otaControl) {
      MockBleGatt.writeOtaControl(device, value);
    } else if (characteristicId == BleGattUuids.logControl) {
      MockBleGatt.writeMeasLogControl(device, value);
    }
  }

  @override
  Stream<List<int>> subscribeCharacteristic({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
  }) {
    final device = _deviceForId(deviceId);
    if (device == null) return const Stream.empty();
    if (characteristicId == BleGattUuids.otaControl) {
      return MockBleGatt.subscribeOtaControl(device);
    }
    if (characteristicId == BleGattUuids.logControl) {
      return MockBleGatt.subscribeMeasLogControl(device);
    }
    if (characteristicId == BleGattUuids.logData) {
      return MockBleGatt.subscribeMeasLogData(device);
    }
    return const Stream.empty();
  }

  @override
  Future<int> requestMtu({
    required String deviceId,
    required int mtu,
  }) async {
    return mtu;
  }

  BleDevice? _deviceForId(String deviceId) {
    for (final state in MockBleGatt._states.values) {
      if (state.device.bleId == deviceId) return state.device;
    }
    return null;
  }
}
