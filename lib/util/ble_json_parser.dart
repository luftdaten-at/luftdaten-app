import 'package:luftdaten.at/model/ble_device.dart';

/// Parses JSON structures sent by the CircuitPython BLE device.
/// Device sends: station.api.key, station.apikey, or top-level apikey.
class BleJsonParser {
  BleJsonParser._();

  /// Extracts API key from BLE JSON. Handles:
  /// - station.api.key (Air Around / get_info)
  /// - station.apikey (base get_info)
  /// - apikey (top-level fallback)
  static String? parseApiKey(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) return null;
    final station = j['station'];
    if (station is Map) {
      final api = station['api'];
      if (api is Map) {
        final key = api['key'];
        if (key is String && key.isNotEmpty) return key;
      }
      final v = station['apikey'];
      if (v is String && v.isNotEmpty) return v;
    }
    final v = j['apikey'];
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  /// Parses firmware version from station.firmware (e.g. "1.5" -> FirmwareVersion(1, 5, 0)).
  static FirmwareVersion? parseFirmwareFromStation(Map<String, dynamic>? station) {
    if (station == null) return null;
    final fw = station['firmware'];
    if (fw is! String) return null;
    final parts = fw.split('.');
    if (parts.isEmpty) return null;
    final major = int.tryParse(parts[0]) ?? 0;
    final minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final patch = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    return FirmwareVersion(major, minor, patch);
  }
}
