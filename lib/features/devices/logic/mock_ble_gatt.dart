import 'dart:math';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt_codec.dart';

class MockBleGattState {
  MockBleGattState({
    required this.device,
    required this.batteryPct,
    required this.operationalFlags,
    required this.airStationConfigTlv,
    required this.sensorValues,
  });

  final BleDevice device;
  double batteryPct;
  int operationalFlags;
  List<int> airStationConfigTlv;
  List<int> sensorValues;
  AirStationConfig? airStationConfig;
  int _telemetryTick = 0;

  void refreshTelemetry() {
    _telemetryTick++;
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
    if (id != null) _states.remove(id);
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
    return const [];
  }

  static void writeCommand(BleDevice device, List<int> value) {
    stateFor(device).handleCommand(value);
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
    if (characteristicId != BleGattUuids.command) return;
    final device = _deviceForId(deviceId);
    if (device == null) return;
    MockBleGatt.writeCommand(device, value);
  }

  BleDevice? _deviceForId(String deviceId) {
    for (final state in MockBleGatt._states.values) {
      if (state.device.bleId == deviceId) return state.device;
    }
    return null;
  }
}
