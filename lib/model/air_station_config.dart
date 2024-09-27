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
    int initialOffset = bytes[0] + 1;
    int settingsByte = bytes[initialOffset];
    return AirStationConfig(
      autoUpdateMode: AutoUpdateMode.parseBinary(settingsByte >> 2),
      batterySaverMode: BatterySaverMode.parseBinary(settingsByte & 3),
      measurementInterval: AirStationMeasurementInterval.parseSeconds(
        bytes[initialOffset + 2] << 8 | bytes[initialOffset + 3],
      ),
    );
  }

  List<int> toBytes() {
    List<int> bytes = [];
    // Byte 0: Protocol version
    bytes.add(2);
    // Byte 1: (Critical updates, all updates, ultra battery saver mode, battery saver mode)
    bytes.add(autoUpdateMode.encoded << 2 | batterySaverMode.encoded);
    // Byte 2: Placeholder empty byte
    bytes.add(0);
    // Bytes 3 & 4: Measurement interval as i16
    bytes.add(measurementInterval.seconds >> 8);
    bytes.add(measurementInterval.seconds & 0xff);
    // Bytes 5 to 32: placeholders for future config options
    for (int i = 0; i < 28; i++) {
      bytes.add(0);
    }
    // Add the Wifi configuration below from here if needed
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
