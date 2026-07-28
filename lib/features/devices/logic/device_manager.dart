import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_disconnect_handler.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';

import '../data/air_station_config.dart';
import '../data/ble_device.dart';
import '../data/chip_id.dart';
import 'device_config_store.dart';

class DeviceManager extends ChangeNotifier {
  static const _autoRefreshInterval = Duration(seconds: 8);
  static const _scanDurationMs = 2000;

  final List<BleDevice> _devices = [];

  List<BleDevice> get devices => _devices;
  GetStorage box = GetStorage('devices');
  bool _scanning = false;

  bool get scanning => _scanning;

  List<String> deviceNamesFoundAtLastScan = [];

  set scanning(bool val) {
    _scanning = val;
    notifyListeners();
  }

  StreamSubscription? _deviceScanner;
  Timer? _autoRefreshTimer;
  bool _devicePageVisible = false;

  @visibleForTesting
  bool get hasAutoRefreshTimerForTest => _autoRefreshTimer != null;

  @visibleForTesting
  bool get isDevicePageVisibleForTest => _devicePageVisible;

  @visibleForTesting
  bool skipAutoRefreshScanForTest = false;

  Future<void> init() async {
    await GetStorage.init('devices');
    List<dynamic> raw = box.read('devices') ?? [];
    for (dynamic element in raw) {
      devices.add(BleDevice.fromJson(element as Map<String, dynamic>));
    }
  }

  /// Starts or stops periodic BLE scans while the Geräte page/tab is visible.
  void setDevicePageVisible(bool visible) {
    if (_devicePageVisible == visible) return;
    _devicePageVisible = visible;
    if (visible) {
      unawaited(_runAutoRefreshCycle());
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
        unawaited(_runAutoRefreshCycle());
      });
    } else {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
    }
  }

  Future<void> _runAutoRefreshCycle() async {
    if (!_devicePageVisible || _scanning) return;
    if (!skipAutoRefreshScanForTest) {
      await scanForDevices(_scanDurationMs);
    }
    _nudgePausedMeasurementReconnect();
  }

  void _nudgePausedMeasurementReconnect() {
    if (!getIt.isRegistered<MeasurementDisconnectHandler>() ||
        !getIt.isRegistered<TripController>()) {
      return;
    }
    final trips = getIt<TripController>();
    final pausedDevice = trips.disconnectPausedDevice;
    if (!trips.isPausedForDisconnect || pausedDevice == null) return;
    getIt<MeasurementDisconnectHandler>()
        .checkPausedDeviceConnection(pausedDevice);
  }

  void saveDeviceList() {
    box.write('devices', devices.map((e) => e.toJson()).toList());
  }

  Future<void> scanForDevices(int durationMS, {List<Uuid>? serviceIds}) {
    Completer completer = Completer();
    HashMap<String, DiscoveredDevice> foundDevices = HashMap();
    Permission.bluetoothScan.request();
    scanning = true;
    notifyListeners();
    _deviceScanner?.cancel();
    deviceNamesFoundAtLastScan = [];
    // Use empty list to discover all devices - withServices filters can fail to find
    // devices (e.g. ESP32) that don't advertise the service in scan response (issue #712)
    _deviceScanner = FlutterReactiveBle()
        .scanForDevices(withServices: serviceIds ?? [])
        .listen((dev) {
      if(dev.name.startsWith('Luftdaten.at')) {
        if(!deviceNamesFoundAtLastScan.contains(dev.name)) {
          deviceNamesFoundAtLastScan.add(dev.name);
        }
      }
      if (foundDevices[dev.name] == null) {
        foundDevices[dev.name] = dev;
        if (devices.where((e) => e.bleName == dev.name).isNotEmpty) {
          final bleDevice = devices.where((e) => e.bleName == dev.name).first;
          logger.d("IncState: ${dev.id}");
          bleDevice
            ..state = BleDeviceState.discovered
            ..bleId = dev.id;
        }
      }
    });
    Future.delayed(Duration(milliseconds: durationMS)).then((_) {
      _deviceScanner?.cancel();
      scanning = false;
      notifyListeners();
      completer.complete();
    });
    return completer.future;
  }

  void addDevice(BleDevice device) {
    devices.add(device);
    notifyListeners();
    saveDeviceList();
  }

  /// Adds a debug mock device (simulator). Reuses existing mock of the same [model].
  BleDevice? addMockDevice(LDDeviceModel model) {
    if (!AppSettings.mockBleActive) return null;
    for (final existing in devices) {
      if (existing.isMock && existing.model == model) {
        return existing;
      }
    }
    final device = MockBleDevices.buildMockDevice(
      model,
      existingBleNames: devices.map((e) => e.bleName),
    );
    addDevice(device);
    return device;
  }

  void addMockPresetBundle() {
    if (!AppSettings.mockBleActive) return;
    addMockDevice(LDDeviceModel.aRound);
    addMockDevice(LDDeviceModel.station);
  }

  BleDevice? addDeviceByCode(String? code) {
    if (code == null) return null;
    try {
      List<String> parts = code.split(';');
      final displayName = parts[0].trim();
      final bleName = parts[1].trim();
      final bleMacAddress = BleDevice.chipIdPattern.hasMatch(displayName)
          ? displayName.mac
          : _bleMacFromBroadcastName(bleName);
      BleDevice device = BleDevice(
        model: LDDeviceModel.fromId(int.parse(parts[2])),
        bleName: bleName,
        bleMacAddress: bleMacAddress,
        deviceOriginalDisplayName: displayName,
        autoReconnect: LDDeviceModel.fromId(int.parse(parts[2])).portable,
      );
      if(devices.map((e) => e.bleName).contains(device.bleName)) {
        return devices.firstWhere((e) => e.bleName == device.bleName);
      } else {
        addDevice(device);
        return device;
      }
    } catch (_) {
      return null;
    }
  }

  void _prepareForDeviceRemoval() {
    if (getIt.isRegistered<TripController>()) {
      final trips = getIt<TripController>();
      if (trips.isOngoing) {
        trips.stopTrip();
      }
    }
    for (final d in devices) {
      if (d.state == BleDeviceState.connected || d.state == BleDeviceState.connecting) {
        d.disconnect();
      }
    }
  }

  void deleteDevice(BleDevice device) {
    _prepareForDeviceRemoval();
    devices.remove(device);
    saveDeviceList();
    if (device.model == LDDeviceModel.station) {
      unawaited(AirStationConfigManager.deleteConfig(device.bleName));
    } else {
      unawaited(DeviceConfigStore.instance.deletePortableConfig(device.bleName));
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  /// MAC segment from BLE broadcast names like `Luftdaten.at-AABBCCDDEEFF-1` or `Luftdaten.at-372D`.
  static String _bleMacFromBroadcastName(String bleName) {
    final segments = bleName.split('-');
    if (segments.length >= 3) return segments[1];
    if (segments.length >= 2) return segments.last;
    return bleName;
  }
}
