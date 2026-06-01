import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_json_parser.dart';
import 'package:luftdaten.at/features/devices/logic/station_secrets_store.dart';

/// Applies an API key read from BLE to [device] and persists it in secure storage.
class DeviceApiKeyBleSync {
  DeviceApiKeyBleSync._();

  /// Sets [BleDevice.apiKey] and writes to [StationSecretsStore] when [key] is non-empty.
  static Future<bool> applyKey(BleDevice device, String key, {String? logSource}) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    device.apiKey = trimmed;
    try {
      await StationSecretsStore.instance.writeApiKey(device.bleName, trimmed);
      logger.d(
        'DeviceApiKeyBleSync: persisted api key for ${device.bleName}'
        '${logSource != null ? ' (source=$logSource)' : ''}',
      );
      return true;
    } catch (e, st) {
      logger.d('DeviceApiKeyBleSync: secure storage write failed: $e ($st)');
      return true;
    }
  }

  /// Parses API key from BLE JSON metadata (`device_info` or sensor wrapper).
  static Future<bool> applyFromBleMetadata(
    BleDevice device,
    Map<String, dynamic>? metadata, {
    String logSource = 'ble_metadata',
  }) async {
    final key = BleJsonParser.parseApiKey(metadata);
    if (key == null || key.isEmpty) return false;
    return applyKey(device, key, logSource: logSource);
  }

  /// Parses TLV flag 20 from Air Station `air_station_configuration` bytes.
  static Future<bool> applyFromAirStationConfigBytes(
    BleDevice device,
    List<int> tlvBytes,
  ) async {
    if (tlvBytes.isEmpty || tlvBytes.length == 1 && tlvBytes[0] == 0) {
      return false;
    }
    final config = AirStationConfig.fromBytes(device.bleName, tlvBytes);
    final key = config.pendingApiKeyForSecureStore;
    if (key == null || key.isEmpty) return false;
    return applyKey(device, key, logSource: 'air_station_configuration_tlv20');
  }
}
