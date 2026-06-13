import 'dart:convert';
import 'dart:typed_data';

// ignore_for_file: constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:i18n_extension/default.i18n.dart';
import 'package:luftdaten.at/core/utils/util.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_store.dart';

/// Firmware TLV string values ([`LOG_LEVEL`](https://github.com/luftdaten-at/firmware/blob/main/docs/settings.md)).
abstract final class AirStationBleLogLevels {
  static const List<String> ordered = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'];
}

/// MQTT / Home Assistant BLE TLV range is flags `9…17`; each Air Station BLE command fragment
/// is `[0x06][ TLV…]` and firmware merges TLV records incrementally (`AirStation.decode_configuration`).
abstract final class AirStationBleHomeAssistantDefaults {
  static const String mqttDiscoveryPrefix = 'homeassistant';
  static const int mqttPortTls = 8883;
  static const int mqttPortPlain = 1883;

  /// Room under custom `max_length=512`; keep margin for headers/stack.
  static const int maxCommandBytesPerWrite = 480;

  /// Splits `[0x06, … TLV…]` payloads into sequential fragment writes (each leading `0x06`).
  static List<List<int>> chunkSetAirStationConfiguration(List<int> payload) {
    if (payload.isEmpty || payload.first != 0x06) {
      throw ArgumentError.value(payload, 'payload', 'Must start with 0x06 (SET_AIR_STATION_CONFIGURATION)');
    }
    final tlvBytes = payload.sublist(1);
    final records = <List<int>>[];
    var i = 0;
    while (i + 2 <= tlvBytes.length) {
      final len = tlvBytes[i + 1];
      if (i + 2 + len > tlvBytes.length) break;
      records.add(tlvBytes.sublist(i, i + 2 + len));
      i += 2 + len;
    }
    if (i != tlvBytes.length) {
      // Malformed TLV; still send whole payload single chunk (best-effort).
      return [payload];
    }
    if (payload.length <= maxCommandBytesPerWrite) return [payload];
    final out = <List<int>>[];
    var current = <int>[0x06];
    for (final rec in records) {
      if (current.length + rec.length > maxCommandBytesPerWrite) {
        if (current.length > 1) out.add(current);
        current = <int>[0x06];
      }
      current.addAll(rec);
    }
    if (current.length > 1) out.add(current);
    return out.isEmpty ? [payload] : out;
  }
}

class AirStationConfig {
  final String id;
  AutoUpdateMode autoUpdateMode;
  BatterySaverMode batterySaverMode;
  AirStationMeasurementInterval measurementInterval;
  double? longitude;
  double? latitude;
  double? height;

  /// IANA TZ name (BLE TLV flag `18`), e.g. `Europe/Vienna`.
  String? tz;

  /// One of [AirStationBleLogLevels.ordered] (BLE flag `19`).
  String? logLevel;

  String? deviceId;

  /// Parsed from TLV `20` on last `fromBytes` read; persists via [StationSecretsStore], not prefs.
  String? pendingApiKeyForSecureStore;

  // --- MQTT over BLE flags 9–17 (non-secret persisted in prefs) ---

  /// `MQTT_ENABLED` (TLV flag `9`). Default off until read/set.
  bool mqttEnabled;

  /// `MQTT_BROKER` (flag `10`).
  String? mqttBroker;

  /// `MQTT_PORT` (flag `11`).
  int mqttPort;

  /// `MQTT_USE_TLS` (flag `12`).
  bool mqttUseTls;

  /// `MQTT_USERNAME` (flag `13`).
  String? mqttUsername;

  /// `MQTT_DISCOVERY_PREFIX` (flag `15`), default HA prefix.
  String? mqttDiscoveryPrefix;

  /// `MQTT_DEVICE_NAME` (flag `16`).
  String? mqttDeviceName;

  /// `MQTT_CERTIFICATE_PATH` (flag `17`) — path **on station** PEM.
  String? mqttCertificatePath;

  // --- Startup one-shots `startup.toml` via BLE flags `21…25` (int32 `0|1`; next boot). ---

  /// TLV `21` (`SYNC_RTC_FROM_NTP`).
  bool syncRtcFromNtp;

  /// TLV `22` (`DETECT_MODEL_FROM_SENSORS`).
  bool detectModelFromSensors;

  /// TLV `23` (`UPLOAD_SD_LOG_TO_DATAHUB`) — sensitive.
  bool uploadSdLogToDatahub;

  /// TLV `24` (`CLEAR_SD_CARD`) — destructive.
  bool clearSdCard;

  /// TLV `25` (`REFRESH_SENSORS`).
  bool refreshSensors;

  /// When the app last successfully saved/applied this configuration.
  DateTime? lastConfiguredAt;

  AirStationConfig({
    required this.id,
    required this.autoUpdateMode,
    required this.batterySaverMode,
    required this.measurementInterval,
    required this.longitude,
    required this.latitude,
    required this.height,
    required this.deviceId,
    this.tz,
    this.logLevel,
    this.pendingApiKeyForSecureStore,
    this.mqttEnabled = false,
    this.mqttBroker,
    this.mqttPort = AirStationBleHomeAssistantDefaults.mqttPortPlain,
    this.mqttUseTls = false,
    this.mqttUsername,
    this.mqttDiscoveryPrefix,
    this.mqttDeviceName,
    this.mqttCertificatePath,
    this.syncRtcFromNtp = false,
    this.detectModelFromSensors = false,
    this.uploadSdLogToDatahub = false,
    this.clearSdCard = false,
    this.refreshSensors = false,
    this.lastConfiguredAt,
  });

  AirStationConfig.defaultConfig(this.id)
      : autoUpdateMode = AutoUpdateMode.on,
        batterySaverMode = BatterySaverMode.normal,
        measurementInterval = AirStationMeasurementInterval.min5,
        longitude = null,
        latitude = null,
        height = null,
        deviceId = null,
        tz = null,
        logLevel = null,
        pendingApiKeyForSecureStore = null,
        mqttEnabled = false,
        mqttBroker = null,
        mqttPort = AirStationBleHomeAssistantDefaults.mqttPortPlain,
        mqttUseTls = false,
        mqttUsername = null,
        mqttDiscoveryPrefix = null,
        mqttDeviceName = null,
        mqttCertificatePath = null,
        syncRtcFromNtp = false,
        detectModelFromSensors = false,
        uploadSdLogToDatahub = false,
        clearSdCard = false,
        refreshSensors = false,
        lastConfiguredAt = null;

  /// Persists non-secret config to secure storage (`api_key` is never stored here).
  Future<void> persist({DateTime? lastConfiguredAt}) async {
    if (lastConfiguredAt != null) {
      this.lastConfiguredAt = lastConfiguredAt;
    }
    await DeviceConfigStore.instance.writeStationConfig(
      this,
      lastConfiguredAt: this.lastConfiguredAt,
    );
    AirStationConfigManager._cache[id] = this;
  }

  /// Applies non-secret snapshot from BLE read (MQTT password / Wi‑Fi pass never arrive here).
  void applyNonSecretSnapshotFromBleRead(AirStationConfig snapshot) {
    autoUpdateMode = snapshot.autoUpdateMode;
    batterySaverMode = snapshot.batterySaverMode;
    measurementInterval = snapshot.measurementInterval;
    longitude = snapshot.longitude;
    latitude = snapshot.latitude;
    height = snapshot.height;
    deviceId = snapshot.deviceId;
    tz = snapshot.tz;
    logLevel = snapshot.logLevel;
    mqttEnabled = snapshot.mqttEnabled;
    mqttBroker = snapshot.mqttBroker;
    mqttPort = snapshot.mqttPort;
    mqttUseTls = snapshot.mqttUseTls;
    mqttUsername = snapshot.mqttUsername;
    mqttDiscoveryPrefix = snapshot.mqttDiscoveryPrefix;
    mqttDeviceName = snapshot.mqttDeviceName;
    mqttCertificatePath = snapshot.mqttCertificatePath;
    syncRtcFromNtp = snapshot.syncRtcFromNtp;
    detectModelFromSensors = snapshot.detectModelFromSensors;
    uploadSdLogToDatahub = snapshot.uploadSdLogToDatahub;
    clearSdCard = snapshot.clearSdCard;
    refreshSensors = snapshot.refreshSensors;
  }

  bool nonSecretFieldsEqual(AirStationConfig other) {
    return autoUpdateMode == other.autoUpdateMode &&
        measurementInterval == other.measurementInterval &&
        longitude == other.longitude &&
        latitude == other.latitude &&
        height == other.height &&
        deviceId == other.deviceId &&
        tz == other.tz &&
        logLevel == other.logLevel &&
        mqttEnabled == other.mqttEnabled &&
        mqttBroker == other.mqttBroker &&
        mqttPort == other.mqttPort &&
        mqttUseTls == other.mqttUseTls &&
        mqttUsername == other.mqttUsername &&
        mqttDiscoveryPrefix == other.mqttDiscoveryPrefix &&
        mqttDeviceName == other.mqttDeviceName &&
        mqttCertificatePath == other.mqttCertificatePath &&
        syncRtcFromNtp == other.syncRtcFromNtp &&
        detectModelFromSensors == other.detectModelFromSensors &&
        uploadSdLogToDatahub == other.uploadSdLogToDatahub &&
        clearSdCard == other.clearSdCard &&
        refreshSensors == other.refreshSensors;
  }

  /// Parses TLV blob without persisting (for BLE sync compare / API key extraction).
  static AirStationConfig parseFromBytes(String id, List<int> bytes) {
    return _parseBytesImpl(id, bytes);
  }

  /// Parses TLV blob from BLE `air_station_configuration` characteristic (without leading command byte).
  factory AirStationConfig.fromBytes(String id, List<int> bytes) {
    return parseFromBytes(id, bytes);
  }

  static AirStationConfig _parseBytesImpl(String id, List<int> bytes) {
    AutoUpdateMode autoUpdateMode = AutoUpdateMode.on;
    BatterySaverMode batterySaverMode = BatterySaverMode.normal;
    AirStationMeasurementInterval measurementInterval = AirStationMeasurementInterval.min5;
    double? longitude;
    double? latitude;
    double? height;
    String? deviceId;
    String? tz;
    String? logLevel;
    String? pendingApiKeyFromBle;

    var mqttEnabled = false;
    String? mqttBroker;
    var mqttPort = AirStationBleHomeAssistantDefaults.mqttPortPlain;
    var mqttUseTls = false;
    String? mqttUsername;
    String? mqttDiscoveryPrefix;
    String? mqttDeviceName;
    String? mqttCertificatePath;

    var syncRtcFromNtp = false;
    var detectModelFromSensors = false;
    var uploadSdLogToDatahub = false;
    var clearSdCard = false;
    var refreshSensors = false;

    double? parseStringToDouble(String value) =>
        value.isNotEmpty ? double.tryParse(value) : null;

    int idx = 0;
    while (idx + 2 <= bytes.length) {
      final rawFlag = bytes[idx++];
      final length = bytes[idx++];
      if (idx + length > bytes.length) {
        break;
      }

      AirStationConfigFlags? flagEnum;
      for (final f in AirStationConfigFlags.values) {
        if (f.value == rawFlag) {
          flagEnum = f;
          break;
        }
      }

      final valueSlice = Uint8List.sublistView(Uint8List.fromList(bytes), idx, idx + length);
      final byteDataSlice = ByteData.sublistView(valueSlice);

      switch (flagEnum) {
        case AirStationConfigFlags.AUTO_UPDATE_MODE:
          if (length == 4) {
            autoUpdateMode =
                AutoUpdateMode.parseBinary(byteDataSlice.getInt32(0, Endian.big));
          }
          break;
        case AirStationConfigFlags.BATTERY_SAVE_MODE:
          if (length == 4) {
            batterySaverMode =
                BatterySaverMode.parseBinary(byteDataSlice.getInt32(0, Endian.big));
          }
          break;
        case AirStationConfigFlags.MEASUREMENT_INTERVAL:
          if (length == 4) {
            measurementInterval = AirStationMeasurementInterval.parseSeconds(
                byteDataSlice.getInt32(0, Endian.big));
          }
          break;
        case AirStationConfigFlags.LONGITUDE:
          longitude = parseStringToDouble(utf8.decode(valueSlice));
          break;
        case AirStationConfigFlags.LATITUDE:
          latitude = parseStringToDouble(utf8.decode(valueSlice));
          break;
        case AirStationConfigFlags.HEIGHT:
          height = parseStringToDouble(utf8.decode(valueSlice));
          break;
        case AirStationConfigFlags.SSID:
        case AirStationConfigFlags.PASSWORD:
          break;
        case AirStationConfigFlags.MQTT_ENABLED:
          if (length == 4) {
            mqttEnabled = byteDataSlice.getInt32(0, Endian.big) != 0;
          }
          break;
        case AirStationConfigFlags.MQTT_BROKER:
          mqttBroker = utf8.decode(valueSlice);
          break;
        case AirStationConfigFlags.MQTT_PORT:
          if (length == 4) {
            mqttPort = byteDataSlice.getInt32(0, Endian.big);
          }
          break;
        case AirStationConfigFlags.MQTT_USE_TLS:
          if (length == 4) {
            mqttUseTls = byteDataSlice.getInt32(0, Endian.big) != 0;
          }
          break;
        case AirStationConfigFlags.MQTT_USERNAME:
          mqttUsername = utf8.decode(valueSlice);
          break;
        case AirStationConfigFlags.MQTT_PASSWORD:
          break;
        case AirStationConfigFlags.MQTT_DISCOVERY_PREFIX:
          mqttDiscoveryPrefix = utf8.decode(valueSlice);
          break;
        case AirStationConfigFlags.MQTT_DEVICE_NAME:
          mqttDeviceName = utf8.decode(valueSlice);
          break;
        case AirStationConfigFlags.MQTT_CERTIFICATE_PATH:
          mqttCertificatePath = utf8.decode(valueSlice);
          break;
        case AirStationConfigFlags.DEVICE_ID:
          deviceId = utf8.decode(valueSlice);
          break;
        case AirStationConfigFlags.TZ:
          tz = utf8.decode(valueSlice);
          break;
        case AirStationConfigFlags.LOG_LEVEL:
          logLevel = utf8.decode(valueSlice);
          break;
        case AirStationConfigFlags.API_KEY:
          pendingApiKeyFromBle = utf8.decode(valueSlice);
          break;
        case AirStationConfigFlags.SYNC_RTC_FROM_NTP:
          if (length == 4) {
            syncRtcFromNtp = byteDataSlice.getInt32(0, Endian.big) != 0;
          }
          break;
        case AirStationConfigFlags.DETECT_MODEL_FROM_SENSORS:
          if (length == 4) {
            detectModelFromSensors = byteDataSlice.getInt32(0, Endian.big) != 0;
          }
          break;
        case AirStationConfigFlags.UPLOAD_SD_LOG_TO_DATAHUB:
          if (length == 4) {
            uploadSdLogToDatahub = byteDataSlice.getInt32(0, Endian.big) != 0;
          }
          break;
        case AirStationConfigFlags.CLEAR_SD_CARD:
          if (length == 4) {
            clearSdCard = byteDataSlice.getInt32(0, Endian.big) != 0;
          }
          break;
        case AirStationConfigFlags.REFRESH_SENSORS:
          if (length == 4) {
            refreshSensors = byteDataSlice.getInt32(0, Endian.big) != 0;
          }
          break;
        case null:
          break;
      }

      idx += length;
    }

    return AirStationConfig(
      id: id,
      autoUpdateMode: autoUpdateMode,
      batterySaverMode: batterySaverMode,
      measurementInterval: measurementInterval,
      longitude: longitude,
      latitude: latitude,
      height: height,
      deviceId: deviceId,
      tz: tz,
      logLevel: logLevel,
      pendingApiKeyForSecureStore:
          pendingApiKeyFromBle == null || pendingApiKeyFromBle.isEmpty
              ? null
              : pendingApiKeyFromBle,
      mqttEnabled: mqttEnabled,
      mqttBroker: mqttBroker,
      mqttPort: mqttPort,
      mqttUseTls: mqttUseTls,
      mqttUsername: mqttUsername,
      mqttDiscoveryPrefix: mqttDiscoveryPrefix,
      mqttDeviceName: mqttDeviceName,
      mqttCertificatePath: mqttCertificatePath,
      syncRtcFromNtp: syncRtcFromNtp,
      detectModelFromSensors: detectModelFromSensors,
      uploadSdLogToDatahub: uploadSdLogToDatahub,
      clearSdCard: clearSdCard,
      refreshSensors: refreshSensors,
    );
  }

  /// Air Station TLV write: `[0x06][records…]` matching firmware decode.
  /// API key (flag `20`) is read from firmware over BLE only; never written from the app.
  List<int> toBytes() {
    List<int> bytes = [0x06];

    void appendInt32Tlv(int flag, int value) {
      bytes.add(flag);
      bytes.add(4);
      bytes.addAll(Util.toByteArray(value));
    }

    void appendUtf8Tlv(int flag, String s) {
      final utf = utf8.encode(s);
      if (utf.length > 255) {
        throw FormatException(
            'BLE TLV UTF-8 value for flag $flag exceeds 255 bytes (got ${utf.length})');
      }
      bytes.add(flag);
      bytes.add(utf.length);
      bytes.addAll(utf);
    }

    appendInt32Tlv(0, autoUpdateMode.encoded);
    appendInt32Tlv(1, batterySaverMode.encoded);
    appendInt32Tlv(2, measurementInterval.seconds);
    appendUtf8Tlv(3, longitude?.toString() ?? '');
    appendUtf8Tlv(4, latitude?.toString() ?? '');
    appendUtf8Tlv(5, height?.toString() ?? '');

    final tzVal = tz?.trim() ?? '';
    if (tzVal.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.TZ.value, tzVal);
    }
    final logVal = logLevel?.trim() ?? '';
    if (logVal.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.LOG_LEVEL.value, logVal);
    }

    return bytes;
  }

  /// TLV payload for MQTT / Home Assistant only (`0x06` + flags `9…17`; optional write-only `14`).
  List<int> toBytesMqttOnly({
    bool appendMqttPasswordTlv14 = false,
    String? mqttPasswordForTlv14,
  }) {
    final bytes = <int>[0x06];

    void appendInt32Tlv(int flag, int value) {
      bytes.add(flag);
      bytes.add(4);
      bytes.addAll(Util.toByteArray(value));
    }

    void appendUtf8Tlv(int flag, String s) {
      final utf = utf8.encode(s);
      if (utf.length > 255) {
        throw FormatException(
            'BLE TLV UTF-8 value for flag $flag exceeds 255 bytes (got ${utf.length})');
      }
      bytes.add(flag);
      bytes.add(utf.length);
      bytes.addAll(utf);
    }

    appendInt32Tlv(AirStationConfigFlags.MQTT_ENABLED.value, mqttEnabled ? 1 : 0);
    appendUtf8Tlv(AirStationConfigFlags.MQTT_BROKER.value, mqttBroker?.trim() ?? '');
    appendInt32Tlv(AirStationConfigFlags.MQTT_PORT.value, mqttPort);
    appendInt32Tlv(AirStationConfigFlags.MQTT_USE_TLS.value, mqttUseTls ? 1 : 0);
    appendUtf8Tlv(AirStationConfigFlags.MQTT_USERNAME.value, mqttUsername ?? '');

    if (appendMqttPasswordTlv14 &&
        mqttPasswordForTlv14 != null &&
        mqttPasswordForTlv14.trim().isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.MQTT_PASSWORD.value, mqttPasswordForTlv14.trim());
    }

    final disc = mqttDiscoveryPrefix?.trim();
    appendUtf8Tlv(
      AirStationConfigFlags.MQTT_DISCOVERY_PREFIX.value,
      disc != null && disc.isNotEmpty
          ? disc
          : AirStationBleHomeAssistantDefaults.mqttDiscoveryPrefix,
    );

    appendUtf8Tlv(AirStationConfigFlags.MQTT_DEVICE_NAME.value, mqttDeviceName?.trim() ?? '');

    final cert = mqttCertificatePath?.trim() ?? '';
    if (cert.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.MQTT_CERTIFICATE_PATH.value, cert);
    }

    return bytes;
  }

  /// Single TLV blob for **`startup.toml`** boot flags (**`21`**, **`23…25`**) merged by firmware incrementally (`0x06` prefix).
  ///
  /// TLV **`22`** is intentionally not surfaced in companion startup BLE UX; use USB / `startup.toml` for that flag.
  List<int> toBytesStartupSingleFlagTlv(AirStationConfigFlags flag, {bool value = true}) {
    switch (flag) {
      case AirStationConfigFlags.SYNC_RTC_FROM_NTP:
      case AirStationConfigFlags.UPLOAD_SD_LOG_TO_DATAHUB:
      case AirStationConfigFlags.CLEAR_SD_CARD:
      case AirStationConfigFlags.REFRESH_SENSORS:
        break;
      default:
        throw ArgumentError.value(
          flag,
          'flag',
          'Only TLV 21 and 23–25 are exposed for companion single-flag startup BLE writes.',
        );
    }

    final bytes = <int>[0x06];
    bytes.add(flag.value);
    bytes.add(4);
    bytes.addAll(Util.toByteArray(value ? 1 : 0));
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
      if (tz != null) 'tz': tz,
      if (logLevel != null) 'logLevel': logLevel,
      'mqttEnabled': mqttEnabled,
      if (mqttBroker != null) 'mqttBroker': mqttBroker,
      'mqttPort': mqttPort,
      'mqttUseTls': mqttUseTls,
      if (mqttUsername != null) 'mqttUsername': mqttUsername,
      if (mqttDiscoveryPrefix != null) 'mqttDiscoveryPrefix': mqttDiscoveryPrefix,
      if (mqttDeviceName != null) 'mqttDeviceName': mqttDeviceName,
      if (mqttCertificatePath != null) 'mqttCertificatePath': mqttCertificatePath,
      'syncRtcFromNtp': syncRtcFromNtp,
      'detectModelFromSensors': detectModelFromSensors,
      'uploadSdLogToDatahub': uploadSdLogToDatahub,
      'clearSdCard': clearSdCard,
      'refreshSensors': refreshSensors,
      if (lastConfiguredAt != null)
        'lastConfiguredAt': lastConfiguredAt!.toIso8601String(),
    };
  }

  factory AirStationConfig.fromJson(Map<String, dynamic> json) {
    return AirStationConfig(
      id: json['id'] as String,
      autoUpdateMode: AutoUpdateMode.parseBinary(json['autoUpdateMode'] as int),
      batterySaverMode: BatterySaverMode.parseBinary(json['batterySaverMode'] as int),
      measurementInterval:
          AirStationMeasurementInterval.parseSeconds(json['measurementInterval'] as int),
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      deviceId: json['deviceId'] as String?,
      tz: json['tz'] as String?,
      logLevel: json['logLevel'] as String?,
      pendingApiKeyForSecureStore: null,
      mqttEnabled: json['mqttEnabled'] as bool? ?? false,
      mqttBroker: json['mqttBroker'] as String?,
      mqttPort: json['mqttPort'] != null
          ? (json['mqttPort'] as num).toInt()
          : AirStationBleHomeAssistantDefaults.mqttPortPlain,
      mqttUseTls: json['mqttUseTls'] as bool? ?? false,
      mqttUsername: json['mqttUsername'] as String?,
      mqttDiscoveryPrefix: json['mqttDiscoveryPrefix'] as String?,
      mqttDeviceName: json['mqttDeviceName'] as String?,
      mqttCertificatePath: json['mqttCertificatePath'] as String?,
      syncRtcFromNtp: json['syncRtcFromNtp'] as bool? ?? false,
      detectModelFromSensors: json['detectModelFromSensors'] as bool? ?? false,
      uploadSdLogToDatahub: json['uploadSdLogToDatahub'] as bool? ?? false,
      clearSdCard: json['clearSdCard'] as bool? ?? false,
      refreshSensors: json['refreshSensors'] as bool? ?? false,
      lastConfiguredAt: json['lastConfiguredAt'] != null
          ? DateTime.parse(json['lastConfiguredAt'] as String)
          : null,
    );
  }
}

class AirStationConfigManager {
  static final Map<String, AirStationConfig> _cache = {};

  static Future<void> loadAllConfigs() async {
    await DeviceConfigStore.instance.migrateFromSharedPreferencesIfNeeded();
    final ids = await DeviceConfigStore.instance.listStationConfigIds();
    for (final id in ids) {
      final record = await DeviceConfigStore.instance.readStationConfig(id);
      if (record == null) continue;
      record.config.lastConfiguredAt =
          record.lastConfiguredAt ?? record.config.lastConfiguredAt;
      _cache[id] = record.config;
    }
  }

  static AirStationConfig? getConfig(String id) => _cache[id];

  /// Mutable clone for editing; does not persist.
  static Future<AirStationConfig?> loadSavedForEdit(String bleName) async {
    final cached = getConfig(bleName);
    if (cached != null) {
      return AirStationConfig.fromJson(cached.toJson());
    }
    final record = await DeviceConfigStore.instance.readStationConfig(bleName);
    if (record == null) return null;
    return AirStationConfig.fromJson(record.config.toJson());
  }

  static void putInCache(AirStationConfig config) {
    _cache[config.id] = config;
  }

  static Future<void> deleteConfig(String id) async {
    await DeviceConfigStore.instance.deleteStationConfig(id);
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
  SSID(6),
  PASSWORD(7),
  DEVICE_ID(8),

  MQTT_ENABLED(9),
  MQTT_BROKER(10),
  MQTT_PORT(11),
  MQTT_USE_TLS(12),
  MQTT_USERNAME(13),
  MQTT_PASSWORD(14),
  MQTT_DISCOVERY_PREFIX(15),
  MQTT_DEVICE_NAME(16),
  MQTT_CERTIFICATE_PATH(17),

  /// IANA TZ (BLE flag `18`).
  TZ(18),

  /// `DEBUG`, `INFO`, … (flag `19`).
  LOG_LEVEL(19),

  /// Datahub/API token (flag `20`) — persisted in secure storage in the app, not prefs.
  API_KEY(20),

  /// `startup.toml` one-shots (int32 `0|1`); applied on **next boot** unless noted in firmware docs.
  SYNC_RTC_FROM_NTP(21),

  DETECT_MODEL_FROM_SENSORS(22),

  /// Sensitive: SD log upload to Datahub.
  UPLOAD_SD_LOG_TO_DATAHUB(23),

  /// Destructive: clears SD storage.
  CLEAR_SD_CARD(24),

  REFRESH_SENSORS(25);

  final int value;

  const AirStationConfigFlags(this.value);

  factory AirStationConfigFlags.fromValue(int x) =>
      AirStationConfigFlags.values.firstWhere((e) => e.value == x);
}

class AirStationWifiConfig {
  TextEditingController ssidController;
  TextEditingController passwordController;

  AirStationWifiConfig({String ssid = '', String password = ''})
      : ssidController = TextEditingController()..text = ssid,
        passwordController = TextEditingController()..text = password;

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
      ssid: json['ssid'] as String,
      password: json['password'] as String,
    );
  }

  /// TLV records for SSID/password (flags `6`/`7`); prefixed with Wi‑Fi data only —
  /// [`AirStationConfig.toBytes`] already supplies leading `0x06`.
  List<int> toBytes() {
    final bytes = <int>[];
    void appendUtf8Tlv(int flag, String s) {
      final encoded = utf8.encode(s);
      if (encoded.length > 255) {
        throw FormatException('WLAN SSID/password UTF-8 length exceeds 255 bytes');
      }
      bytes.add(flag);
      bytes.add(encoded.length);
      bytes.addAll(encoded);
    }

    appendUtf8Tlv(6, ssid);
    appendUtf8Tlv(7, password);
    return bytes;
  }

  bool get valid => ssid.length >= 2 && password.length >= 8;

  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
  }
}

enum AutoUpdateMode {
  on('An (Empfohlen)', 1 << 1 | 1),
  critical('Nur kritische', 1 << 1),
  off('Aus', 0);

  final String _name;
  final int encoded;

  const AutoUpdateMode(this._name, this.encoded);

  @override
  String toString() => _name.i18n;

  factory AutoUpdateMode.parseString(String name) =>
      AutoUpdateMode.values.where((e) => e.toString() == name).first;

  factory AutoUpdateMode.parseBinary(int binary) =>
      AutoUpdateMode.values.where((e) => e.encoded == binary).firstOrNull ?? AutoUpdateMode.on;
}

enum BatterySaverMode {
  ultra('Ultra', 1 << 1 | 1),
  normal('Normal (Empfohlen)', 1),
  off('Aus', 0);

  final String _name;
  final int encoded;

  const BatterySaverMode(this._name, this.encoded);

  @override
  String toString() => _name.i18n;

  factory BatterySaverMode.parseString(String name) =>
      BatterySaverMode.values.where((e) => e.toString() == name).first;

  factory BatterySaverMode.parseBinary(int binary) =>
      BatterySaverMode.values.where((e) => e.encoded == binary).firstOrNull ??
      BatterySaverMode.normal;
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
  String toString() => _name.i18n;

  factory AirStationMeasurementInterval.parseString(String name) =>
      AirStationMeasurementInterval.values.where((e) => e.toString() == name).first;

  factory AirStationMeasurementInterval.parseSeconds(int seconds) =>
      AirStationMeasurementInterval.values.where((e) => e.seconds == seconds).firstOrNull ??
      AirStationMeasurementInterval.min5;
}

extension IterableFirstOrNullFixed<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
