import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';
import 'package:collection_providers/collection_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/controller/http_provider.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/model/air_station_config.dart';
import 'package:luftdaten.at/model/ble_device.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_controller.dart';

class AirStationConfigWizardController extends ChangeNotifier {
  static final MapChangeNotifier<String, AirStationConfigWizardController> _activeControllers = MapChangeNotifier();
  static final GetStorage _box = GetStorage('air-station-wizard');

  static MapChangeNotifier<String, AirStationConfigWizardController> get activeControllers => _activeControllers;

  static Future<void> init() async {
    await GetStorage.init('air-station-wizard');
    List actives = _box.read('active') ?? [];
    for (dynamic e in actives) {
      AirStationConfigWizardController c =
          AirStationConfigWizardController.fromJson((e as Map).cast<String, dynamic>());
      // Check which phase to resume from
      if(c.firstDataSuccessReceivedAt != null) {
        c.waitForFirstData();
      } else if(c.configSentAt != null) {
        c.waitForFirstData();
      } else if(c.configLoadedAt != null) {
        if(DateTime.now().difference(c.configLoadedAt!).inMinutes > 15) {
          c.config = null;
          c.wifi = null;
          // Resume from standard connection screen
        } else {
          c.stage = AirStationConfigWizardStage.editSettings;
        }
      } else {
        // Resume from standard connection screen
      }
      _activeControllers[c.id] = c;
    }
  }

  factory AirStationConfigWizardController(String id) {
    if(_activeControllers[id] == null) {
      _activeControllers[id] = AirStationConfigWizardController._(id)..verifyDeviceState();
    }
    return _activeControllers[id]!;
  }

  static void removeController(String id) {
    _activeControllers.remove(id);
    _activeControllers[id]?.notifyListeners();
    saveAll();
  }

  static void saveAll() {
    List<Map<String, dynamic>> list = [];
    for (AirStationConfigWizardController e in _activeControllers.values) {
      list.add(e.toJson());
    }
    _box.write('active', list);
  }

  final String id;

  AirStationConfigWizardController._(this.id);

  // Serialization
  factory AirStationConfigWizardController.fromJson(Map<String, dynamic> json) {
    AirStationConfigWizardController c = AirStationConfigWizardController._(json['id']);
    if(json['config'] != null) {
      c.config = AirStationConfig.fromJson((json['config'] as Map).cast<String, dynamic>());
    }
    if(json['wifi'] != null) {
      c.wifi = AirStationWifiConfig.fromJson((json['wifi'] as Map).cast<String, dynamic>());
    }
    if(json['configLoadedAt'] != null) {
      c._configLoadedAt = DateTime.parse(json['configLoadedAt']);
    }
    if(json['configSentAt'] != null) {
      c._configSentAt = DateTime.parse(json['configSentAt']);
    }
    if(json['firstDataSuccessReceivedAt'] != null) {
      c._firstDataSuccessReceivedAt = DateTime.parse(json['firstDataSuccessReceivedAt']);
    }
    return c;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (config != null) 'config': config!.toJson(),
      if (wifi != null) 'wifi': wifi!.toJson(),
      if(configLoadedAt != null) 'configLoadedAt': configLoadedAt!.toIso8601String(),
      if(configSentAt != null) 'configSentAt': configSentAt!.toIso8601String(),
      if(firstDataSuccessReceivedAt != null) 'firstDataSuccessReceivedAt': firstDataSuccessReceivedAt!.toIso8601String(),
    };
  }

  // Actual controller logic below
  AirStationConfigWizardStage _stage = AirStationConfigWizardStage.verifyingDeviceState;
  AirStationConfigWizardStage get stage => _stage;
  set stage(AirStationConfigWizardStage val) {
    _stage = val;
    notifyListeners();
  }

  AirStationConfig? config;

  AirStationWifiConfig? wifi;

  DateTime? _configLoadedAt, _configSentAt, _firstDataSuccessReceivedAt;

  DateTime? get configLoadedAt => _configLoadedAt;

  set configLoadedAt(DateTime? time) {
    _configLoadedAt = time;
    saveAll();
  }

  DateTime? get configSentAt => _configSentAt;

  set configSentAt(DateTime? time) {
    _configSentAt = time;
    saveAll();
  }

  DateTime? get firstDataSuccessReceivedAt => _firstDataSuccessReceivedAt;

  set firstDataSuccessReceivedAt(DateTime? time) {
    _firstDataSuccessReceivedAt = time;
    saveAll();
  }

  void verifyDeviceState() async {
    switch (FlutterReactiveBle().status) {
      case BleStatus.unknown:
        logger.e('BleStatus unknown (this should not happen)');
      case BleStatus.unsupported:
        stage = AirStationConfigWizardStage.deviceDoesNotSupportBLE;
        break;
      case BleStatus.poweredOff:
        stage = AirStationConfigWizardStage.bluetoothTurnedOff;
        break;
      case BleStatus.locationServicesDisabled:
        stage = AirStationConfigWizardStage.gpsPermissionMissing;
        break;
      case BleStatus.unauthorized:
        stage = AirStationConfigWizardStage.blePermissionMissing;
        break;
      case BleStatus.ready:
        checkDeviceConnection();
        break;
    }
    notifyListeners();
  }

  Future<void> requestBluetoothPowerOn() async {
    bool res = bool.tryParse(await BluetoothEnable.enableBluetooth) ?? false;
    if (res) {
      // This can only happen on Android, where the method waits
      verifyDeviceState();
    } else {
      // On iOS, bluetooth may still have been enabled. But just include a "check again" button.
      // Check every sec for 10 secs, just in case
      for(int i=0;i<10;i++) {
        await Future.delayed(const Duration(seconds: 1));
        if(stage != AirStationConfigWizardStage.bluetoothTurnedOff) return;
        if(FlutterReactiveBle().status != BleStatus.poweredOff) {
          // Bluetooth has been activated in the meantime, continue
          verifyDeviceState();
        }
      }
    }
  }

  Future<void> requestNearbyDevicesPermission() async {
    // Make sure to also include text on enabling this from settings
    if ((await Permission.bluetoothScan.request()) == PermissionStatus.granted) {
      verifyDeviceState();
    }
  }

  Future<void> requestGpsPermission() async {
    if((await Permission.location.request()) == PermissionStatus.granted) {
      verifyDeviceState();
    }
  }

  // TODO: we probably need to include where to navigate to after this
  Future<void> checkDeviceConnection() async {
    BleDevice dev = getIt<DeviceManager>().devices.where((e) => e.bleName == id).first;
    if (dev.state == BleDeviceState.connected) {
      if(config != null) {
        _transmitConfiguration();
      } else {
        _moveOnToLoadingConfig();
      }
    } else if (dev.state == BleDeviceState.discovered || dev.state == BleDeviceState.disconnected) {
      _attemptConnectionToDevice();
    } else {
      stage = AirStationConfigWizardStage.scanningForDevices;
      getIt<DeviceManager>().scanForDevices(1800);
      await Future.delayed(const Duration(milliseconds: 2000));
      if (dev.state == BleDeviceState.discovered || dev.state == BleDeviceState.disconnected) {
        _attemptConnectionToDevice();
      } else {
        stage = AirStationConfigWizardStage.deviceNotVisible;
      }
    }
  }

  Future<void> _attemptConnectionToDevice() async {
    stage = AirStationConfigWizardStage.attemptingConnection;
    BleDevice dev = getIt<DeviceManager>().devices.where((e) => e.bleName == id).first;
    for (int i = 0; i < 15; i++) {
      // Attempt connection up to 60 times (depending on how long it takes) over 30 seconds,
      // checking status every two seconds
      if (dev.state == BleDeviceState.discovered || dev.state == BleDeviceState.disconnected) {
        dev.connect();
      }
      await Future.delayed(const Duration(milliseconds: 2000));
      if (dev.state == BleDeviceState.connected) {
        if(config != null) {
          _transmitConfiguration();
        } else {
          _moveOnToLoadingConfig();
        }
        return;
      }
    }
    // Connection failed
    if(config != null) {
      stage = AirStationConfigWizardStage.connectionLostAndNotReestablished;
    } else {
      stage = AirStationConfigWizardStage.connectionFailed;
    }
  }

  Future<void> _moveOnToLoadingConfig() async {
    stage = AirStationConfigWizardStage.loadingConfig;
    BleDevice dev = getIt<DeviceManager>().devices.where((e) => e.bleName == id).first;
    try {
      List<int> bytes = await getIt<BleController>().readAirStationConfiguration(dev) ?? [];
      config = AirStationConfig.fromBytes(bytes);
      configLoadedAt = DateTime.now();
      saveAll();
    } catch (_) {
      // Reading or parsing failed
      stage = AirStationConfigWizardStage.failedToLoadConfig;
      return;
    }
    // Config has been loaded successfully
    stage = AirStationConfigWizardStage.editSettings;
  }

  Future<void> sendConfiguration() async {
    saveAll();
    verifyDeviceState();
  }

  Future<void> _transmitConfiguration() async {
    stage = AirStationConfigWizardStage.sending;
    BleDevice dev = getIt<DeviceManager>().devices.where((e) => e.bleName == id).first;
    try {
      List<int> bytes = config!.toBytes();

      print("airstation config bytes");
      print(bytes);
      
      if(wifi?.valid??false) {
        print("add wifi config");
        bytes.addAll(wifi!.toBytes());
      }

      print("bytes with wifi config");
      print(bytes);

      bool success = await getIt<BleController>().sendAirStationConfig(dev, bytes);
      dev.disconnect();
      if(success) {
        // TODO this is temporary until firmware is updated
        // (though it may remain the permanent solution for old-firmware devices)
        stage = AirStationConfigWizardStage.checkLed;
        configSentAt = DateTime.now();
      } else {
        stage = AirStationConfigWizardStage.configTransmissionFailed;
      }
    } catch(_) {
      stage = AirStationConfigWizardStage.configTransmissionFailed;
    }
  }

  Future<void> waitForFirstData() async {
    stage = AirStationConfigWizardStage.waitingForFirstData;
    // TODO periodically check for data
    _shouldStillCheckForData = true;
    _checkForDataOnline();
  }

  bool _shouldStillCheckForData = false;

  Future<void> _checkForDataOnline() async {
    DateTime scanningFrom = DateTime.now();
    while(true) {
      if(!_shouldStillCheckForData) {
        return;
      }
      int waitedForSeconds = DateTime.now().difference(configSentAt!).inSeconds;
      int shouldWaitFor = config!.measurementInterval.seconds * 3 + 60;
      int scanningForSeconds = DateTime.now().difference(scanningFrom).inSeconds;
      int shouldScanForAtLeast = 60;
      if(waitedForSeconds > shouldWaitFor && scanningForSeconds > shouldScanForAtLeast) {
        stage = AirStationConfigWizardStage.firstDataFailed;
        return;
      }
      SingleStationHttpProvider provider = SingleStationHttpProvider(id.split('-').last, true, false);
      await provider.refetch();
      if(provider.error) {
        stage = AirStationConfigWizardStage.firstDataCheckFailed;
        return;
      } else if(provider.items[1].isEmpty) {
        // Continue waiting
      } else {
        // Check if there's data that is more recent than our config changes
        if(provider.items[1].last.timestamp.compareTo(configSentAt!) < 0) {
          logger.d('Config sent at: ${configSentAt!}');
          logger.d('Most recent values: ${provider.items[1].last.timestamp}');
          // Most recent values were sent before config changed, keep waiting
        } else {
          // New data has been found, finish
          stage = AirStationConfigWizardStage.firstDataSuccess;
          firstDataSuccessReceivedAt = DateTime.now();
          return;
        }
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}

/// These correspond to different pages that are shown in the wizard.
/// Error messages are defined separately
enum AirStationConfigWizardStage {
  verifyingDeviceState, // This one might be unnecessary?
  deviceDoesNotSupportBLE,
  bluetoothTurnedOff,
  blePermissionMissing,
  scanningForDevices,
  scanFailed, // This is meant for when FlutterReactiveBle scan is denied by rate-limitation. Not yet implemented.
  attemptingConnection,
  deviceNotVisible,
  deviceNotVisibleButBLEButtonBlue,
  deviceNotVisibleAndBLEButtonNotBlue,
  connectionFailed,
  loadingConfig,
  failedToLoadConfig,
  editSettings,
  configureWifiChoice,
  editWifi,
  sending,
  configTransmissionFailed,
  connectionLostAndNotReestablished,
  loadingStatus, // TODO - not yet implemented in firmware
  pingFailed, // TODO - not yet implemented in firmware
  configInvalid, // TODO - not yet implemented in firmware
  configSuccess, // TODO - not yet implemented in firmware
  checkLed, // Placeholder "what's the LED doing" screen here
  genericWifiFailure, // Placeholder until we know more from device
  waitingForFirstData,
  firstDataSuccess,
  firstDataFailed,
  firstDataCheckFailed,
  setLocation,
  gpsPermissionMissing
}
