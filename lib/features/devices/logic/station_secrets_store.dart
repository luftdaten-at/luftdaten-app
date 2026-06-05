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

  String _wifiSsidLookupKey(String stationId) => 'station_wifi_ssid_$stationId';

  String _wifiPasswordLookupKey(String stationId) =>
      'station_wifi_password_$stationId';

  Future<void> writeWifiCredentials(
    String stationId, {
    required String ssid,
    required String password,
  }) async {
    await _storage.write(key: _wifiSsidLookupKey(stationId), value: ssid);
    await _storage.write(key: _wifiPasswordLookupKey(stationId), value: password);
  }

  Future<String?> readWifiSsid(String stationId) =>
      _storage.read(key: _wifiSsidLookupKey(stationId));

  Future<String?> readWifiPassword(String stationId) =>
      _storage.read(key: _wifiPasswordLookupKey(stationId));

  Future<void> deleteWifiCredentials(String stationId) async {
    await _storage.delete(key: _wifiSsidLookupKey(stationId));
    await _storage.delete(key: _wifiPasswordLookupKey(stationId));
  }
}
