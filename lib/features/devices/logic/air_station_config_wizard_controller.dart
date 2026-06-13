import 'dart:async';

import 'package:bluetooth_enable/bluetooth_enable.dart';
import 'package:collection_providers/collection_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator package for GPS

import 'ble_controller.dart';
import 'device_api_key_ble_sync.dart';
import 'air_station_setup_verification.dart';
import 'station_secrets_store.dart';

class AirStationConfigWizardController extends ChangeNotifier {
  static final MapChangeNotifier<String, AirStationConfigWizardController> _activeControllers = MapChangeNotifier();
  static final GetStorage _box = GetStorage('air-station-wizard');

  static MapChangeNotifier<String, AirStationConfigWizardController> get activeControllers => _activeControllers;

  @visibleForTesting
  static BleStatus? debugBleStatus;

  @visibleForTesting
  static void resetForTests() {
    debugBleStatus = null;
  }

  Position currentPosition = Position(
    latitude: 0.0,
    longitude: 0.0,
    timestamp: DateTime.now(),
    altitude: 0.0,
    accuracy: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0
  );

  static Future<void> init() async {
    await GetStorage.init('air-station-wizard');
    List actives = _box.read('active') ?? [];
    for (dynamic e in actives) {
      AirStationConfigWizardController c =
          AirStationConfigWizardController.fromJson((e as Map).cast<String, dynamic>());
      // Check which phase to resume from
      if (c.firstDataSuccessReceivedAt != null) {
        c.stage = c.geoWarningOnSuccess
            ? AirStationConfigWizardStage.firstDataSuccessWithGeoWarning
            : AirStationConfigWizardStage.firstDataSuccess;
      } else if (c.configSentAt != null) {
        c.waitForFirstData();
      } else if(c.configLoadedAt != null) {
        if(DateTime.now().difference(c.configLoadedAt!).inMinutes > 15) {
          c.config = null;
          c.wifi = null;
          // Resume from standard connection screen
        } else {
          c.stage = AirStationConfigWizardStage.editSettings;
          unawaited(c.prepareBleStationFormControllers());
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
    final ctrl = _activeControllers[id];
    ctrl?.disposeBleStationFormControllers();
    ctrl?.wifi?.dispose();
    _activeControllers.remove(id);
    saveAll();
  }

  @visibleForTesting
  static AirStationConfigWizardController createForTest(String id) {
    removeController(id);
    final ctrl = AirStationConfigWizardController._(id);
    _activeControllers[id] = ctrl;
    return ctrl;
  }

  @visibleForTesting
  Future<void> hydrateFromSavedConfigForTest() =>
      _hydrateFromSavedConfigIfNeeded();

  @visibleForTesting
  void armConfigTransmitForTest() {
    _pendingConfigTransmit = true;
  }

  @visibleForTesting
  Future<void> onConnectedForTest() async {
    if (_pendingConfigTransmit && config != null) {
      _pendingConfigTransmit = false;
      await _transmitConfiguration();
    } else if (config != null) {
      stage = AirStationConfigWizardStage.editSettings;
      await prepareBleStationFormControllers();
    }
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
    c.geoWarningOnSuccess = json['geoWarningOnSuccess'] == true;
    if (json['lastVerificationApiLat'] != null) {
      c.lastVerificationApiLat = (json['lastVerificationApiLat'] as num).toDouble();
    }
    if (json['lastVerificationApiLon'] != null) {
      c.lastVerificationApiLon = (json['lastVerificationApiLon'] as num).toDouble();
    }
    if (json['lastVerificationGeoDistanceM'] != null) {
      c.lastVerificationGeoDistanceM =
          (json['lastVerificationGeoDistanceM'] as num).toDouble();
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
      'geoWarningOnSuccess': geoWarningOnSuccess,
      if (lastVerificationApiLat != null) 'lastVerificationApiLat': lastVerificationApiLat,
      if (lastVerificationApiLon != null) 'lastVerificationApiLon': lastVerificationApiLon,
      if (lastVerificationGeoDistanceM != null)
        'lastVerificationGeoDistanceM': lastVerificationGeoDistanceM,
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

  bool _pendingConfigTransmit = false;

  /// True when Wi‑Fi password exists in secure storage (not shown in the form).
  bool hasStoredWifiPassword = false;

  /// TLV 18 (`TZ`) editing — IANA name, e.g. `Europe/Vienna`.
  TextEditingController? tzBleController;

  DateTime? _configLoadedAt, _configSentAt, _firstDataSuccessReceivedAt;

  bool geoWarningOnSuccess = false;
  double? lastVerificationApiLat;
  double? lastVerificationApiLon;
  double? lastVerificationGeoDistanceM;

  SetupVerificationProgress? verificationProgress;
  bool _verificationLoopActive = false;

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

  /// Rebuilds TZ text controller after [config] changes (BLE read or default).
  Future<void> prepareBleStationFormControllers() async {
    disposeBleStationFormControllers();
    final cfg = config;
    tzBleController = TextEditingController(text: cfg?.tz ?? '');
    notifyListeners();
  }

  void disposeBleStationFormControllers() {
    tzBleController?.dispose();
    tzBleController = null;
  }

  Future<void> _hydrateFromSavedConfigIfNeeded() async {
    if (config != null) return;
    if (configLoadedAt != null || configSentAt != null) return;

    final saved = await AirStationConfigManager.loadSavedForEdit(id);
    if (saved == null) return;

    config = saved;
    final ssid = await StationSecretsStore.instance.readWifiSsid(id);
    if (ssid != null && ssid.isNotEmpty) {
      wifi = AirStationWifiConfig(ssid: ssid);
    }
    final storedPw = await StationSecretsStore.instance.readWifiPassword(id);
    hasStoredWifiPassword = storedPw != null && storedPw.isNotEmpty;
    await prepareBleStationFormControllers();
    stage = AirStationConfigWizardStage.editSettings;
    saveAll();
  }

  void verifyDeviceState() async {
    await _hydrateFromSavedConfigIfNeeded();
    // update position
    switch (debugBleStatus ?? FlutterReactiveBle().status) {
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
        // for Android >= 12
        await Permission.bluetoothConnect.request();
        checkDeviceConnection();
        break;
    }
    getCurrentLocation();
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
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
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
      if (_pendingConfigTransmit && config != null) {
        _pendingConfigTransmit = false;
        _transmitConfiguration();
      } else if (config != null) {
        stage = AirStationConfigWizardStage.editSettings;
        await prepareBleStationFormControllers();
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
        if (_pendingConfigTransmit && config != null) {
          _pendingConfigTransmit = false;
          _transmitConfiguration();
        } else if (config != null) {
          stage = AirStationConfigWizardStage.editSettings;
          await prepareBleStationFormControllers();
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
      config = AirStationConfig.fromBytes(id, bytes);
      configLoadedAt = DateTime.now();
      saveAll();
      final pending = config!.pendingApiKeyForSecureStore;
      if (pending != null && pending.isNotEmpty) {
        await DeviceApiKeyBleSync.applyKey(dev, pending, logSource: 'wizard_air_station_configuration');
        config!.pendingApiKeyForSecureStore = null;
      }
      await prepareBleStationFormControllers();
    } catch (e) {
      // Reading or parsing failed
      stage = AirStationConfigWizardStage.failedToLoadConfig;
      return;
    }
    // Config has been loaded successfully
    stage = AirStationConfigWizardStage.editSettings;
  }

  Future<void> sendConfiguration() async {
    _pendingConfigTransmit = true;
    saveAll();
    verifyDeviceState();
  }

  Future<void> _transmitConfiguration() async {
    stage = AirStationConfigWizardStage.sending;
    BleDevice dev = getIt<DeviceManager>().devices.where((e) => e.bleName == id).first;
    try {
      final tzTrimmed = tzBleController?.text.trim() ?? '';
      config!.tz = tzTrimmed.isEmpty ? null : tzTrimmed;

      List<int> bytes = config!.toBytes();

      if (wifi?.valid ?? false) {
        bytes.addAll(wifi!.toBytes());
      }

      bool success = await getIt<BleController>().sendAirStationConfig(dev, bytes);
      dev.disconnect();
      if (success) {
        try {
          if (wifi?.valid ?? false) {
            await StationSecretsStore.instance.writeWifiCredentials(
              id,
              ssid: wifi!.ssid,
              password: wifi!.password,
            );
          }
          await config!.persist(lastConfiguredAt: DateTime.now());
          AirStationConfigManager.putInCache(config!);
        } catch (_) {
          /* best-effort; device already accepted config */
        }
        stage = AirStationConfigWizardStage.checkLed;
        configSentAt = DateTime.now();
      } else {
        stage = AirStationConfigWizardStage.configTransmissionFailed;
      }
    } catch (_) {
      stage = AirStationConfigWizardStage.configTransmissionFailed;
    }
  }

  Future<void> waitForFirstData() async {
    stage = AirStationConfigWizardStage.waitingForFirstData;
    verificationProgress = SetupVerificationProgress();
    notifyListeners();
    if (_verificationLoopActive) return;
    _verificationLoopActive = true;
    try {
      await _checkForDataOnline();
    } finally {
      _verificationLoopActive = false;
    }
  }

  BleDevice? _wizardBleDevice() {
    try {
      return getIt<DeviceManager>().devices.firstWhere((e) => e.bleName == id);
    } catch (_) {
      return null;
    }
  }

  bool _bleHasWifiFailure(BleDevice dev) {
    return dev.operationalNotices.any((n) =>
        n.id == 'wifi_failure' ||
        n.id == 'wifi_credentials_missing' ||
        n.id == 'wifi_ssid_not_found' ||
        n.id == 'wifi_connection_failed');
  }

  bool _bleHasConfigIncomplete(BleDevice dev) {
    return dev.operationalNotices.any((n) => n.id == 'config_incomplete');
  }

  Future<bool> _refreshBleStatusIfConnected() async {
    final dev = _wizardBleDevice();
    if (dev == null || dev.state != BleDeviceState.connected) return false;
    try {
      await getIt<BleController>().refreshDeviceStatus(dev);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if polling should stop (stage changed).
  Future<bool> _blePreflightDuringWait() async {
    if (stage != AirStationConfigWizardStage.waitingForFirstData) return true;
    if (!await _refreshBleStatusIfConnected()) return false;
    final dev = _wizardBleDevice();
    if (dev == null) return false;
    if (_bleHasWifiFailure(dev)) {
      stage = AirStationConfigWizardStage.genericWifiFailure;
      return true;
    }
    if (_bleHasConfigIncomplete(dev)) {
      stage = AirStationConfigWizardStage.editSettings;
      return true;
    }
    return false;
  }

  Future<void> _checkForDataOnline() async {
    final deviceId = AirStationSetupVerification.resolveDeviceId(config, id);
    if (deviceId.isEmpty) {
      logger.d('setup verification: no device id for $id');
      stage = AirStationConfigWizardStage.firstDataFailed;
      return;
    }

    final expectedLat = config?.latitude;
    final expectedLon = config?.longitude;
    final deadline = DateTime.now().add(AirStationSetupVerification.maxWait);
    var attempt = 0;
    var consecutiveNetworkErrors = 0;

    while (DateTime.now().isBefore(deadline)) {
      if (stage != AirStationConfigWizardStage.waitingForFirstData) return;
      if (await _blePreflightDuringWait()) return;

      attempt++;
      final result = await AirStationSetupVerification.runAttempt(
        deviceId: deviceId,
        expectedLatitude: expectedLat,
        expectedLongitude: expectedLon,
      );

      verificationProgress = SetupVerificationProgress(
        attemptCount: attempt,
        measurementsOk: result.measurementsFound,
        geoOk: result.geoMatchesExpected,
        apiLatitude: result.apiLatitude,
        apiLongitude: result.apiLongitude,
        geoDistanceMeters: result.geoDistanceMeters,
        lastCheckAt: DateTime.now(),
        lastError: result.errorMessage,
      );
      notifyListeners();

      switch (result.outcome) {
        case SetupVerificationOutcome.completeSuccess:
          firstDataSuccessReceivedAt = DateTime.now();
          geoWarningOnSuccess = false;
          lastVerificationApiLat = result.apiLatitude;
          lastVerificationApiLon = result.apiLongitude;
          lastVerificationGeoDistanceM = result.geoDistanceMeters;
          stage = AirStationConfigWizardStage.firstDataSuccess;
          saveAll();
          return;
        case SetupVerificationOutcome.successMeasurementsOnly:
          firstDataSuccessReceivedAt = DateTime.now();
          geoWarningOnSuccess = true;
          lastVerificationApiLat = result.apiLatitude;
          lastVerificationApiLon = result.apiLongitude;
          lastVerificationGeoDistanceM = result.geoDistanceMeters;
          stage = AirStationConfigWizardStage.firstDataSuccessWithGeoWarning;
          saveAll();
          return;
        case SetupVerificationOutcome.networkError:
          consecutiveNetworkErrors++;
          if (consecutiveNetworkErrors >= 3) {
            stage = AirStationConfigWizardStage.firstDataCheckFailed;
            return;
          }
          break;
        case SetupVerificationOutcome.noMeasurementsYet:
        case SetupVerificationOutcome.pending:
          consecutiveNetworkErrors = 0;
          break;
      }

      if (DateTime.now().isBefore(deadline)) {
        await Future.delayed(AirStationSetupVerification.pollInterval);
      }
    }

    if (stage == AirStationConfigWizardStage.waitingForFirstData) {
      stage = AirStationConfigWizardStage.firstDataFailed;
    }
  }

  // Method to fetch current location
  Future<void> getCurrentLocation() async {
    if(await Permission.location.request() == PermissionStatus.granted){
      currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
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
  firstDataSuccessWithGeoWarning,
  firstDataFailed,
  firstDataCheckFailed,
  setLocation,
  gpsPermissionMissing
}
