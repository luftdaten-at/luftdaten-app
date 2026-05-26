import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists sensitive station values (`api_key`, MQTT password TLV `14`) per BLE broadcast name
/// (same id as [AirStationConfig.id] / [AirStationConfigWizardController.id]).
///
/// Matches firmware: [Luftdaten BLE characteristics](https://github.com/luftdaten-at/firmware/blob/main/docs/ble-characteristics.md).
class StationSecretsStore {
  StationSecretsStore._();

  /// Global instance (no DI registration needed).
  static final StationSecretsStore instance = StationSecretsStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _apiKeyLookupKey(String stationId) => 'station_api_key_$stationId';

  String _mqttPasswordLookupKey(String stationId) =>
      'station_mqtt_password_$stationId';

  Future<void> writeApiKey(String stationId, String value) =>
      _storage.write(key: _apiKeyLookupKey(stationId), value: value);

  Future<String?> readApiKey(String stationId) =>
      _storage.read(key: _apiKeyLookupKey(stationId));

  Future<void> deleteApiKey(String stationId) =>
      _storage.delete(key: _apiKeyLookupKey(stationId));

  /// MQTT TLV `14` (`MQTT_PASSWORD`): never returned on BLE config read-back.
  Future<void> writeMqttPassword(String stationId, String value) =>
      _storage.write(key: _mqttPasswordLookupKey(stationId), value: value);

  Future<String?> readMqttPassword(String stationId) =>
      _storage.read(key: _mqttPasswordLookupKey(stationId));

  Future<void> deleteMqttPassword(String stationId) =>
      _storage.delete(key: _mqttPasswordLookupKey(stationId));
}
