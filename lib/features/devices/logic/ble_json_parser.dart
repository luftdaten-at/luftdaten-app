import 'package:luftdaten.at/features/devices/data/ble_device.dart';

/// Parses JSON structures sent by the CircuitPython BLE device.
/// Device sends: station.api.key, device.api.key, station.apikey, or top-level apikey.
class BleJsonParser {
  BleJsonParser._();

  /// Extracts API key from BLE JSON. Handles:
  /// - station.api.key (Air Station / get_info)
  /// - station.apikey
  /// - device.api.key (portable models / get_info)
  /// - device.apikey
  /// - apikey on device block or top-level
  static String? parseApiKey(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) return null;

    final fromStation = _parseApiKeyFromBlock(j['station']);
    if (fromStation != null) return fromStation;

    final fromDevice = _parseApiKeyFromBlock(j['device']);
    if (fromDevice != null) return fromDevice;

    final top = j['apikey'];
    if (top is String && top.isNotEmpty) return top;
    return null;
  }

  static String? _parseApiKeyFromBlock(Object? block) {
    if (block is! Map) return null;
    final map = Map<String, dynamic>.from(block);
    final api = map['api'];
    if (api is Map) {
      final key = api['key'];
      if (key is String && key.isNotEmpty) return key;
    }
    final apikey = map['apikey'];
    if (apikey is String && apikey.isNotEmpty) return apikey;
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
