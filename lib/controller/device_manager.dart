import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/ble_device.dart';

class DeviceManager extends ChangeNotifier {
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

  Future<void> init() async {
    await GetStorage.init('devices');
    List<dynamic> raw = box.read('devices') ?? [];
    for (dynamic element in raw) {
      devices.add(BleDevice.fromJson(element as Map<String, dynamic>));
    }
    if(devices.isNotEmpty) {
      Future.delayed(const Duration(seconds: 1)).then((_) => scanForDevices(3000));
    }
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
      logger.d("Found device: $dev -> ${dev.id}");
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

  BleDevice? addDeviceByCode(String? code) {
    if (code == null) return null;
    try {
      List<String> parts = code.split(';');
      BleDevice device = BleDevice(
        model: LDDeviceModel.fromId(int.parse(parts[2])),
        bleName: parts[1],
        bleMacAddress: parts[1].split('-')[1],
        deviceOriginalDisplayName: parts[0],
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

  void deleteDevice(BleDevice device) {
    devices.remove(device);
    saveDeviceList();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}
