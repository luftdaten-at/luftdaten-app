import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/controller/battery_info_aggregator.dart';
import 'package:luftdaten.at/controller/ble_controller.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/features/measurement/controllers/trip_controller.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/model/battery_details.dart';
import 'package:luftdaten.at/model/ble_device.i18n.dart';
import 'package:luftdaten.at/model/device_error.dart';
import 'package:luftdaten.at/model/sensor_details.dart';

import 'package:luftdaten.at/shared/widgets/ui.dart';

class BleDevice extends ChangeNotifier {
  // Device state
  BleDeviceState _state = BleDeviceState.unknown;

  BleDeviceState get state => _state;

  set state(BleDeviceState state) {
    _state = state;
    notifyListeners();
    getIt<BatteryInfoAggregator>().onConnectionStatusUpdated();
  }

  StreamSubscription<ConnectionStateUpdate>? _connection;

  // User-configured within the app
  bool _autoReconnect = true;

  bool get autoReconnect => _autoReconnect;

  set autoReconnect(bool value) {
    _autoReconnect = value;
    getIt<DeviceManager>().saveDeviceList();
  }

  int? _measurementInterval;
  String? _userAssignedName;

  int get measurementInterval => _measurementInterval ?? 10;

  set measurementInterval(int val) {
    _measurementInterval = val;
    getIt<DeviceManager>().saveDeviceList();
  }

  String get displayName => _userAssignedName ?? deviceOriginalDisplayName;

  set userAssignedName(String? name) {
    _userAssignedName = name;
    notifyListeners();
    getIt<DeviceManager>().saveDeviceList();
  }

  // Immutable device properties
  LDDeviceModel model;

  /// Device name as broadcast over BLE. This is required to identify the device when scanning for
  /// nearby BLE devices. To connect to a device, use [bleId] instead.
  String bleName;

  /// Device display name as specified in the QR code.
  String deviceOriginalDisplayName;

  /// MAC address without colons (use .toMac to add colons).
  String bleMacAddress;

  String get fourLetterCode =>
      deviceOriginalDisplayName.substring(deviceOriginalDisplayName.length - 4);

  bool get portable => model.portable;

  // Device properties that are read once connected
  FirmwareVersion? firmwareVersion;
  List<SensorDetails>? availableSensors;
  int? protocolVersion;
  BatteryDetails? _batteryDetails;

  // Increment on every BLE readout loop
  int batteryReadoutCounter = 0;

  bool get needsBatteryReadout {
    // Read out battery if there are no battery details available
    if(_batteryDetails?.timestamp == null) return true;
    // Read out battery if the last readout is older than 5 minutes
    if (DateTime.now().difference(_batteryDetails!.timestamp!).inSeconds > 300) return true;
    // Read out battery every 10th iteration
    return batteryReadoutCounter >= 10;
  }

  BatteryDetails? get batteryDetails => _batteryDetails;

  set batteryDetails(BatteryDetails? details) {
    _batteryDetails = details;
    notifyListeners();
  }

  List<DeviceError> errors = [];

  /// Identifier that is used to connect to a BLE device. On Android, this is the MAC address.
  /// On iOS, this is a unique identifier which can change between app starts, and is extracted
  /// by comparing nearby devices' names with [bleName].
  String? bleId;

  // Constructor
  BleDevice(
      {required this.model,
      required this.bleName,
      required this.bleMacAddress,
      required this.deviceOriginalDisplayName,
      bool autoReconnect = true,
      String? userAssignedName,
      int? measurementInterval,
      this.bleId})
      : _autoReconnect = autoReconnect,
        _userAssignedName = userAssignedName,
        _measurementInterval = measurementInterval;

  // Serialize & de-serialize properties
  Map<String, dynamic> toJson() {
    return {
      'deviceBleName': bleName,
      'bleMacAddress': bleMacAddress,
      'deviceOriginalName': deviceOriginalDisplayName,
      'modelName': model.name,
      'autoConnect': autoReconnect,
      if (_measurementInterval != null) 'measurementInterval': _measurementInterval,
      if (_userAssignedName != null) 'userAssignedName': _userAssignedName,
    };
  }

  factory BleDevice.fromJson(Map<String, dynamic> json) {
    return BleDevice(
      model: json['model'] != null
          ? LDDeviceModel.fromId(json['model'])
          : LDDeviceModel.fromName(json['modelName']),
      bleName: json['deviceBleName'],
      bleMacAddress: json['bleMacAddress'],
      autoReconnect: json['autoConnect'],
      measurementInterval: json['measurementInterval'],
      userAssignedName: json['userAssignedName'],
      deviceOriginalDisplayName: json['deviceOriginalName'],
    );
  }

  Future<bool> connect() async {
    BleController ble = getIt<BleController>();
    Completer<bool> completer = Completer();
    state = BleDeviceState.connecting;
    // Scan for BLE device if this device was not yet found
    if (bleId == null) {
      // Scan for BLE devices
      await getIt<DeviceManager>().scanForDevices(2000);
      // If we still haven't found the device, return false
      if (bleId == null) {
        state = BleDeviceState.notFound;
        completer.complete(false);
        return completer.future;
      }
    }
    _connection?.cancel();
    _connection = null;
    _connection = ble.connectTo(this).listen((event) async {
      switch (event.connectionState) {
        case DeviceConnectionState.connecting:
          state = BleDeviceState.connecting;
          break;
        case DeviceConnectionState.connected:
          // We want to get more info about the device before showing it as connected
          state = BleDeviceState.connecting;
          try {
            await ble.getDeviceDetailsAndCheckProtocol(this);
            state = BleDeviceState.connected;
            completer.complete(true);
          } on IncompatibleFirmwareException catch (e) {
            state = BleDeviceState.error;
            _connection?.cancel();
            _connection = null;
            if (globalKey.currentContext != null) {
              showLDDialog(
                globalKey.currentContext!,
                content: Text(
                  'Gerät %s kommuniziert über eine nicht erkanntes Protokoll (Version %i). Bitte update deine App.'
                      .i18n
                      .fill([displayName, e.protocolVersion]),
                  textAlign: TextAlign.center,
                ),
                title: 'Inkompatible Firmware'.i18n,
                icon: Icons.nearby_error,
                color: Colors.red,
              );
            }
            completer.complete(false);
          }
          break;
        default:
          state = BleDeviceState.disconnected;
          if (globalKey.currentContext != null &&
              getIt<TripController>().isOngoing &&
              getIt<TripController>().ongoingTrips.containsKey(this)) {
            getIt<TripController>().stopTrip();
            showLDDialog(
              globalKey.currentContext!,
              text: 'Verbindung zu Bluetooth-Gerät wurde getrennt.'.i18n,
              title: 'Verbindung getrennt'.i18n,
              icon: Icons.nearby_error,
              color: Colors.red,
            );
          }
          completer.complete(false);
          break;
      }
    })
      ..onError((_) {
        // Connection attempt timed out
        state = BleDeviceState.error;
        completer.complete(false);
      });
    return completer.future;
  }

  void disconnect() {
    _connection?.cancel();
    _connection = null;
    state = BleDeviceState.disconnected;
  }

  String get formattedMacAddress => bleMacAddress.asMac;

  factory BleDevice.unknown() {
    return BleDevice(
      model: LDDeviceModel.unknownPortable,
      bleName: 'unknown',
      bleMacAddress: 'unknown',
      deviceOriginalDisplayName: 'unknown',
    );
  }

  void notify() => notifyListeners();
}

enum BleDeviceState { error, unknown, notFound, discovered, connecting, connected, disconnected }

enum LDDeviceModel {
  aRound(id: 1, portable: true, name: 'Air aRound'),
  cube(id: 2, portable: false, name: 'Air Cube'),
  station(id: 3, portable: false, name: 'Air Station'),
  badge(id: 4, portable: true, name: 'Air Badge'),
  bike(id: 5, portable: true, name: 'Air Bike'),
  unknownPortable(id: 0, portable: true, name: 'Unbekanntes Gerät');

  const LDDeviceModel({required this.id, required this.portable, required this.name});

  final int id;
  final bool portable;
  final String name;

  factory LDDeviceModel.fromId(int id) => LDDeviceModel.values.where((e) => e.id == id).first;

  factory LDDeviceModel.fromLegacyId(int id) {
    switch (id) {
      case 2:
        return LDDeviceModel.aRound;
      case 3:
        return LDDeviceModel.station;
      case 4:
        return LDDeviceModel.badge;
      default:
        return LDDeviceModel.unknownPortable;
    }
  }

  factory LDDeviceModel.fromName(String name) =>
      LDDeviceModel.values.where((e) => e.name == name).first;
}

class FirmwareVersion {
  final int major, minor, patch;

  const FirmwareVersion(this.major, this.minor, [this.patch = 0]);

  @override
  String toString() {
    return '$major.$minor.$patch';
  }
}

extension FormatAsMac on String {
  String get asMac {
    StringBuffer buffer = StringBuffer(substring(0, 2));
    for (int i = 1; i < length / 2; i++) {
      buffer.write(':${substring(i * 2, i * 2 + 2)}');
    }
    return buffer.toString();
  }
}
