import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:i18n_extension/default.i18n.dart';
import 'package:luftdaten.at/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AirStationConfig {
  final String id;
  AutoUpdateMode autoUpdateMode;
  BatterySaverMode batterySaverMode;
  AirStationMeasurementInterval measurementInterval;
  double? longitude;
  double? latitude;
  double? height;
  String? deviceId;

  AirStationConfig({
    required this.id,
    required this.autoUpdateMode,
    required this.batterySaverMode,
    required this.measurementInterval,
    required this.longitude,
    required this.latitude,
    required this.height,
    required this.deviceId,
  }) {
    _saveToStorage();
  }

  AirStationConfig.defaultConfig(String id)
      : id = id,
        autoUpdateMode = AutoUpdateMode.on,
        batterySaverMode = BatterySaverMode.normal,
        measurementInterval = AirStationMeasurementInterval.min5,
        longitude = null,
        latitude = null,
        height = null,
        deviceId = null {
    _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = jsonEncode(toJson());
    await prefs.setString('air_station_config_$id', configJson);
    AirStationConfigManager._cache[id] = this;
  }

  factory AirStationConfig.fromBytes(String id, List<int> bytes) {
    print('RECEIVED DATA');
    print(bytes);

    AutoUpdateMode autoUpdateMode = AutoUpdateMode.on;
    BatterySaverMode batterySaverMode = BatterySaverMode.normal;
    AirStationMeasurementInterval measurementInterval = AirStationMeasurementInterval.min5;
    double? longitude;
    double? latitude;
    double? height;
    String? deviceId;

    double? parseStringToDouble(String value) {
      return value.isNotEmpty ? double.tryParse(value) : null;
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
    int idx = 0;
    while (idx < bytes.length) {
      final flag = AirStationConfigFlags.fromValue(byteData.getUint8(idx++));
      final int length = byteData.getUint8(idx++);
      switch (flag) {
        case AirStationConfigFlags.AUTO_UPDATE_MODE:
          autoUpdateMode = AutoUpdateMode.parseBinary(byteData.getInt32(idx));
          break;
        case AirStationConfigFlags.BATTERY_SAVE_MODE:
          batterySaverMode = BatterySaverMode.parseBinary(byteData.getInt32(idx));
          break;
        case AirStationConfigFlags.MEASUREMENT_INTERVAL:
          measurementInterval = AirStationMeasurementInterval.parseSeconds(byteData.getInt32(idx));
          break;
        case AirStationConfigFlags.LONGITUDE:
          longitude = parseStringToDouble(String.fromCharCodes(bytes.sublist(idx, idx + length)));
          break;
        case AirStationConfigFlags.LATITUDE:
          latitude = parseStringToDouble(String.fromCharCodes(bytes.sublist(idx, idx + length)));
          break;
        case AirStationConfigFlags.HEIGHT:
          height = parseStringToDouble(String.fromCharCodes(bytes.sublist(idx, idx + length)));
          break;
        case AirStationConfigFlags.DEVICE_ID:
          deviceId = String.fromCharCodes(bytes.sublist(idx, idx + length));
          break;
      }
      idx += length;
    }

    final config = AirStationConfig(
      id: id,
      autoUpdateMode: autoUpdateMode,
      batterySaverMode: batterySaverMode,
      measurementInterval: measurementInterval,
      longitude: longitude,
      latitude: latitude,
      height: height,
      deviceId: deviceId,
    );

    config._saveToStorage();
    return config;
  }

  List<int> toBytes() {
    // 0x06 indicates that the AirStation configuration is sent
    List<int> bytes = [0x06];
    
    // data to send
    List<Object> data = [
      autoUpdateMode.encoded,
      batterySaverMode.encoded,
      measurementInterval.seconds,
      longitude.toString(),
      latitude.toString(),
      height.toString()
    ];

    for(int i=0; i<data.length; i++){
      List<int> l = Util.toByteArray(data[i]);
      // flag
      bytes.add(i);
      // lenght
      bytes.add(l.length);
      // data
      bytes.addAll(l);
    }

    return bytes;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'autoUpdateMode': autoUpdateMode.encoded,
      'batterySaverMode': batterySaverMode.encoded,
      'measurementInterval': measurementInterval.seconds,
      'longitude': longitude,
      'latitude': latitude,
      'height': height,
      'deviceId': deviceId,
    };
  }

  factory AirStationConfig.fromJson(Map<String, dynamic> json) {
    return AirStationConfig(
      id: json['id'],
      autoUpdateMode: AutoUpdateMode.parseBinary(json['autoUpdateMode']),
      batterySaverMode: BatterySaverMode.parseBinary(json['batterySaverMode']),
      measurementInterval: AirStationMeasurementInterval.parseSeconds(json['measurementInterval']),
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      deviceId: json['deviceId'],
    );
  }
}

class AirStationConfigManager {
  static final Map<String, AirStationConfig> _cache = {};

  static Future<void> loadAllConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('air_station_config_'));

    for (var key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        final config = AirStationConfig.fromJson(json);
        _cache[config.id] = config;
      }
    }
  }

  static AirStationConfig? getConfig(String id) {
    return _cache[id];
  }

  static Future<void> deleteConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('air_station_config_$id');
    _cache.remove(id);
  }
}


enum AirStationConfigFlags {
  AUTO_UPDATE_MODE(0),
  BATTERY_SAVE_MODE(1),
  MEASUREMENT_INTERVAL(2),
  LONGITUDE(3),
  LATITUDE(4),
  HEIGHT(5),
  DEVICE_ID(8);

  final int value;
  
  const AirStationConfigFlags(this.value);
  factory AirStationConfigFlags.fromValue(int x) {
    return AirStationConfigFlags.values.where((e) => e.value == x).first;
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
    bytes.add(6);
    bytes.add(ssid.length);
    bytes.addAll(utf8.encode(ssid));
    bytes.add(7);
    bytes.add(password.length);
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
