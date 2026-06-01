import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_json_parser.dart';
import 'package:luftdaten.at/features/devices/logic/station_secrets_store.dart';

/// Where [DeviceApiKeyResolver] found the Datahub API key.
enum DeviceApiKeySource {
  bleMetadata,
  deviceCache,
  secureStorage,
  missing,
}

/// Result of resolving a device API key for Datahub uploads.
class DeviceApiKeyResolution {
  const DeviceApiKeyResolution({this.key, required this.source});

  final String? key;
  final DeviceApiKeySource source;

  bool get hasKey => key != null && key!.isNotEmpty;
}

typedef StoredApiKeyReader = Future<String?> Function(String bleName);

/// Resolves Datahub `device.apikey` from BLE metadata, in-memory device cache, or secure storage.
class DeviceApiKeyResolver {
  DeviceApiKeyResolver._();

  static StoredApiKeyReader storedApiKeyReader =
      StationSecretsStore.instance.readApiKey;

  /// BLE JSON (per measurement) → [BleDevice.apiKey] → [StationSecretsStore].
  static Future<DeviceApiKeyResolution> resolve({
    required BleDevice device,
    Map<String, dynamic>? bleMetadata,
    StoredApiKeyReader? readStored,
  }) async {
    final read = readStored ?? storedApiKeyReader;

    final fromBle = BleJsonParser.parseApiKey(bleMetadata);
    if (fromBle != null && fromBle.isNotEmpty) {
      return DeviceApiKeyResolution(key: fromBle, source: DeviceApiKeySource.bleMetadata);
    }

    final cached = device.apiKey?.trim();
    if (cached != null && cached.isNotEmpty) {
      return DeviceApiKeyResolution(key: cached, source: DeviceApiKeySource.deviceCache);
    }

    final stored = await read(device.bleName);
    if (stored != null && stored.trim().isNotEmpty) {
      final key = stored.trim();
      device.apiKey = key;
      return DeviceApiKeyResolution(key: key, source: DeviceApiKeySource.secureStorage);
    }

    return const DeviceApiKeyResolution(source: DeviceApiKeySource.missing);
  }

  /// Loads API key from secure storage into [device] when BLE did not provide one.
  static Future<void> hydrateDeviceFromSecureStorage(BleDevice device) async {
    if (device.apiKey != null && device.apiKey!.trim().isNotEmpty) return;
    final stored = await storedApiKeyReader(device.bleName);
    if (stored != null && stored.trim().isNotEmpty) {
      device.apiKey = stored.trim();
    }
  }
}
