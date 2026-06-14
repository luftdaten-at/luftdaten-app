import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';

/// Resolves human-readable station names from Datahub (`/api/v1/devices/name/`).
///
/// Network station ids from api.luftdaten.at (e.g. `1SC`) are mapped to the Datahub
/// lookup key by stripping a trailing `SC` when the prefix is numeric.
class StationNameResolver extends ChangeNotifier {
  StationNameResolver({http.Client? client}) : _client = client ?? http.Client();

  static const String _nameHost = 'datahub.luftdaten.at';

  final http.Client _client;
  final Map<String, String> _cache = {};
  final Map<String, Future<void>> _pending = {};

  String? nameFor(String stationId) => _cache[stationId];

  /// Local [BleDevice] names take precedence over API lookup.
  String displayLabel({
    required String stationId,
    BleDevice? localDevice,
    required String Function(String stationId) fallback,
  }) {
    if (localDevice != null) return localDevice.displayName;
    final cached = _cache[stationId];
    if (cached != null && cached.isNotEmpty) return cached;
    final scPrefix = numericScPrefix(stationId);
    if (scPrefix != null) return 'Station ${scPrefix}SC';
    return fallback(stationId);
  }

  Future<void> ensureLoaded(String stationId) async {
    if (stationId.isEmpty || _cache.containsKey(stationId)) return;
    _pending[stationId] ??= _fetch(stationId);
    await _pending[stationId];
  }

  /// Datahub accepts auto-number (`1`), full device id, etc. Map ids like `1SC` use the numeric prefix.
  static String datahubLookupKey(String stationId) {
    final prefix = numericScPrefix(stationId);
    if (prefix != null) return prefix;
    return stationId.trim();
  }

  /// Returns the numeric part when [stationId] is `{int}SC` (e.g. `1SC` → `1`).
  static String? numericScPrefix(String stationId) {
    final trimmed = stationId.trim();
    if (trimmed.endsWith('SC') && trimmed.length > 2) {
      final prefix = trimmed.substring(0, trimmed.length - 2);
      if (int.tryParse(prefix) != null) return prefix;
    }
    return null;
  }

  static String formatNameForStationId(String stationId, String apiDeviceName) {
    final scPrefix = numericScPrefix(stationId);
    if (scPrefix != null) return 'Station ${scPrefix}SC';
    return apiDeviceName;
  }

  Future<void> _fetch(String stationId) async {
    try {
      final uri = Uri.https(
        _nameHost,
        '/api/v1/devices/name/',
        <String, String>{'device': datahubLookupKey(stationId)},
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        logger.d('StationNameResolver: $stationId HTTP ${response.statusCode}');
        return;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return;
      final name = decoded['device_name']?.toString().trim();
      if (name == null || name.isEmpty) return;
      _cache[stationId] = formatNameForStationId(stationId, name);
      notifyListeners();
    } catch (e, st) {
      logger.d('StationNameResolver: failed for $stationId: $e $st');
    } finally {
      _pending.remove(stationId);
    }
  }

  @visibleForTesting
  void putCachedNameForTest(String stationId, String name) {
    _cache[stationId] = name;
  }

  @visibleForTesting
  void clearCacheForTest() {
    _cache.clear();
    _pending.clear();
  }
}
