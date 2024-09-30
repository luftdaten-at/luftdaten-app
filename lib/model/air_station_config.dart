import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:i18n_extension/default.i18n.dart';

class AirStationConfig {
  AutoUpdateMode autoUpdateMode;
  BatterySaverMode batterySaverMode;
  AirStationMeasurementInterval measurementInterval;

  AirStationConfig({
    required this.autoUpdateMode,
    required this.batterySaverMode,
    required this.measurementInterval,
  });

  AirStationConfig.defaultConfig()
      : autoUpdateMode = AutoUpdateMode.on,
        batterySaverMode = BatterySaverMode.normal,
        measurementInterval = AirStationMeasurementInterval.min5;

  factory AirStationConfig.fromBytes(List<int> bytes) {
    return AirStationConfig(
      autoUpdateMode: AutoUpdateMode.parseBinary(bytes[0]),
      batterySaverMode: BatterySaverMode.parseBinary(bytes[1]),
      measurementInterval: AirStationMeasurementInterval.parseSeconds(bytes[2])
    );
  }

  List<int> toBytes() {
    List<int> bytes = [
      autoUpdateMode.encoded, 
      batterySaverMode.encoded,
      measurementInterval.seconds 
    ];
    return bytes;
  }

  Map<String, dynamic> toJson() {
    return {
      'bytes': toBytes(),
    };
  }

  factory AirStationConfig.fromJson(Map<String, dynamic> json) {
    return AirStationConfig.fromBytes((json['bytes'] as List).cast<int>());
  }
}

class AirStationWifiConfig {
  TextEditingController ssidController, passwordController;

  AirStationWifiConfig({String ssid = '', String password = ''}) :
  ssidController = TextEditingController()..text = ssid, passwordController = TextEditingController()..text = password;

  String get ssid => ssidController.text;

  String get password => passwordController.text;

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'password': password,
    };
  }

  factory AirStationWifiConfig.fromJson(Map<String, dynamic> json) {
    return AirStationWifiConfig(
      ssid: json['ssid'],
      password: json['password'],
    );
  }

  List<int> toBytes() {
    List<int> bytes = [];
    bytes.add(ssid.length);
    bytes.add(0); // Flag for SSID
    bytes.addAll(utf8.encode(ssid));
    bytes.add(password.length);
    bytes.add(1); // Flag for password
    bytes.addAll(utf8.encode(password));
    return bytes;
  }

  bool get valid => ssid.length >= 2 && password.length >= 8;
}

enum AutoUpdateMode {
  on('An (Empfohlen)', 1 << 1 | 1),
  critical('Nur kritische', 1 << 1),
  off('Aus', 0);

  final String _name;
  final int encoded;

  const AutoUpdateMode(this._name, this.encoded);

  @override
  String toString() {
    return _name.i18n;
  }

  factory AutoUpdateMode.parseString(String name) {
    return AutoUpdateMode.values.where((e) => e.toString() == name).first;
  }

  factory AutoUpdateMode.parseBinary(int binary) {
    return AutoUpdateMode.values.where((e) => e.encoded == binary).firstOrNull ?? AutoUpdateMode.on;
  }
}

enum BatterySaverMode {
  ultra('Ultra', 1 << 1 | 1),
  normal('Normal (Empfohlen)', 1),
  off('Aus', 0);

  final String _name;
  final int encoded;

  const BatterySaverMode(this._name, this.encoded);

  @override
  String toString() {
    return _name.i18n;
  }

  factory BatterySaverMode.parseString(String name) {
    return BatterySaverMode.values.where((e) => e.toString() == name).first;
  }

  factory BatterySaverMode.parseBinary(int binary) {
    return BatterySaverMode.values.where((e) => e.encoded == binary).firstOrNull ??
        BatterySaverMode.normal;
  }
}

enum AirStationMeasurementInterval {
  sec30('30 Sekunden', 30),
  min1('1 Minute', 60),
  min3('3 Minuten', 180),
  min5('5 Minuten (Empfohlen)', 300),
  min10('10 Minuten', 600),
  min15('15 Minuten', 900),
  min30('30 Minuten', 1800),
  h1('1 Stunde', 3600);

  final String _name;
  final int seconds;

  const AirStationMeasurementInterval(this._name, this.seconds);

  @override
  String toString() {
    return _name.i18n;
  }

  factory AirStationMeasurementInterval.parseString(String name) {
    return AirStationMeasurementInterval.values.where((e) => e.toString() == name).first;
  }

  factory AirStationMeasurementInterval.parseSeconds(int seconds) {
    return AirStationMeasurementInterval.values.where((e) => e.seconds == seconds).firstOrNull ??
        AirStationMeasurementInterval.min5;
  }
}
