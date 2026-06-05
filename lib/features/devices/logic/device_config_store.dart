import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-side portable preferences snapshot (measurement interval, auto-connect, display name).
class PortableDeviceConfig {
  const PortableDeviceConfig({
    required this.bleName,
    required this.measurementInterval,
    required this.autoReconnect,
    this.userAssignedName,
    this.lastConfiguredAt,
  });

  final String bleName;
  final int measurementInterval;
  final bool autoReconnect;
  final String? userAssignedName;
  final DateTime? lastConfiguredAt;

  Map<String, dynamic> toJson() => {
        'bleName': bleName,
        'measurementInterval': measurementInterval,
        'autoReconnect': autoReconnect,
        if (userAssignedName != null) 'userAssignedName': userAssignedName,
        if (lastConfiguredAt != null)
          'lastConfiguredAt': lastConfiguredAt!.toIso8601String(),
      };

  factory PortableDeviceConfig.fromJson(Map<String, dynamic> json) {
    return PortableDeviceConfig(
      bleName: json['bleName'] as String,
      measurementInterval: (json['measurementInterval'] as num).toInt(),
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      userAssignedName: json['userAssignedName'] as String?,
      lastConfiguredAt: json['lastConfiguredAt'] != null
          ? DateTime.parse(json['lastConfiguredAt'] as String)
          : null,
    );
  }
}

/// Persisted station config envelope (non-secret fields + timestamp).
class StationConfigRecord {
  const StationConfigRecord({
    required this.config,
    this.lastConfiguredAt,
  });

  final AirStationConfig config;
  final DateTime? lastConfiguredAt;

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        if (lastConfiguredAt != null)
          'lastConfiguredAt': lastConfiguredAt!.toIso8601String(),
      };

  factory StationConfigRecord.fromJson(Map<String, dynamic> json) {
    final configMap = (json['config'] as Map).cast<String, dynamic>();
    final lastAt = json['lastConfiguredAt'] as String?;
    return StationConfigRecord(
      config: AirStationConfig.fromJson(configMap),
      lastConfiguredAt: lastAt != null ? DateTime.parse(lastAt) : null,
    );
  }
}

/// Secure storage for device configuration snapshots (Keychain / EncryptedSharedPreferences).
class DeviceConfigStore {
  DeviceConfigStore._();

  static final DeviceConfigStore instance = DeviceConfigStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _legacyPrefsPrefix = 'air_station_config_';
  static const _stationKeyPrefix = 'station_config_';
  static const _portableKeyPrefix = 'portable_config_';
  static const _migrationDoneKey = 'device_config_store_migrated_v1';
  static const _stationIdsManifestKey = 'station_config_ids_manifest';

  String _stationKey(String bleName) => '$_stationKeyPrefix$bleName';

  String _portableKey(String bleName) => '$_portableKeyPrefix$bleName';

  Future<List<String>> listStationConfigIds() => _readStationIdsManifest();

  Future<void> writeStationConfig(
    AirStationConfig config, {
    DateTime? lastConfiguredAt,
  }) async {
    final record = StationConfigRecord(
      config: config,
      lastConfiguredAt: lastConfiguredAt ?? config.lastConfiguredAt,
    );
    await _storage.write(
      key: _stationKey(config.id),
      value: jsonEncode(record.toJson()),
    );
    await _addStationIdToManifest(config.id);
  }

  Future<StationConfigRecord?> readStationConfig(String bleName) async {
    final raw = await _storage.read(key: _stationKey(bleName));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StationConfigRecord.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteStationConfig(String bleName) async {
    await _storage.delete(key: _stationKey(bleName));
    await _removeStationIdFromManifest(bleName);
  }

  Future<List<String>> _readStationIdsManifest() async {
    final raw = await _storage.read(key: _stationIdsManifestKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as String).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _addStationIdToManifest(String id) async {
    final ids = await _readStationIdsManifest();
    if (ids.contains(id)) return;
    ids.add(id);
    await _storage.write(key: _stationIdsManifestKey, value: jsonEncode(ids));
  }

  Future<void> _removeStationIdFromManifest(String id) async {
    final ids = await _readStationIdsManifest();
    if (!ids.contains(id)) return;
    ids.remove(id);
    await _storage.write(key: _stationIdsManifestKey, value: jsonEncode(ids));
  }

  Future<void> writePortableConfig(PortableDeviceConfig config) async {
    await _storage.write(
      key: _portableKey(config.bleName),
      value: jsonEncode(config.toJson()),
    );
  }

  Future<PortableDeviceConfig?> readPortableConfig(String bleName) async {
    final raw = await _storage.read(key: _portableKey(bleName));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PortableDeviceConfig.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> deletePortableConfig(String bleName) async {
    await _storage.delete(key: _portableKey(bleName));
  }

  /// One-time migration from SharedPreferences `air_station_config_*` keys.
  Future<void> migrateFromSharedPreferencesIfNeeded() async {
    final done = await _storage.read(key: _migrationDoneKey);
    if (done == 'true') return;

    final prefs = await SharedPreferences.getInstance();
    final legacyKeys =
        prefs.getKeys().where((k) => k.startsWith(_legacyPrefsPrefix)).toList();

    for (final key in legacyKeys) {
      final jsonString = prefs.getString(key);
      if (jsonString == null) continue;
      try {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        final config = AirStationConfig.fromJson(map);
        final existing = await readStationConfig(config.id);
        if (existing == null) {
          await writeStationConfig(config);
        } else {
          await _addStationIdToManifest(config.id);
        }
        await prefs.remove(key);
      } catch (_) {
        /* skip corrupt legacy entry */
      }
    }

    await _storage.write(key: _migrationDoneKey, value: 'true');
  }

  /// Seeds portable snapshots from persisted device list when none exist yet.
  Future<void> seedPortableSnapshotsIfMissing({
    required Iterable<({String bleName, int measurementInterval, bool autoReconnect, String? userAssignedName})> devices,
  }) async {
    for (final d in devices) {
      final existing = await readPortableConfig(d.bleName);
      if (existing != null) continue;
      await writePortableConfig(
        PortableDeviceConfig(
          bleName: d.bleName,
          measurementInterval: d.measurementInterval,
          autoReconnect: d.autoReconnect,
          userAssignedName: d.userAssignedName,
        ),
      );
    }
  }
}
