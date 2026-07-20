import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';

/// Outcome of `POST /api/v1/devices/status/` for badge registration.
enum DatahubRegisterResult {
  success,
  wrongApiKey,
  failed,
}

/// Datahub device lookup and first-time registration for portable devices.
///
/// Registration uses `POST /api/v1/devices/status/`, which creates the device via
/// Datahub's `get_or_create_station` when it is not yet known.
class DatahubDeviceRegistrationClient {
  DatahubDeviceRegistrationClient({
    http.Client? client,
    String? serverHost,
  })  : _client = client ?? http.Client(),
        _serverHostOverride = serverHost;

  final http.Client _client;
  final String? _serverHostOverride;

  String get _serverHost =>
      _serverHostOverride ??
      (AppSettings.I.useStagingServer ? 'staging.datahub.luftdaten.at' : 'datahub.luftdaten.at');

  Uri _nameUri(String deviceId) => Uri.https(
        _serverHost,
        '/api/v1/devices/name/',
        <String, String>{'device': deviceId},
      );

  Uri get _statusUri => Uri.https(_serverHost, '/api/v1/devices/status/');

  /// Returns `true` when the device exists in Datahub, `false` on HTTP 404.
  Future<bool> isDeviceRegistered(String deviceId) async {
    final trimmed = deviceId.trim();
    if (trimmed.isEmpty) return false;
    final response = await _client.get(_nameUri(trimmed));
    logger.d('Datahub device lookup $trimmed -> HTTP ${response.statusCode}');
    if (response.statusCode == 200) return true;
    if (response.statusCode == 404) return false;
    throw StateError('Datahub device lookup failed: HTTP ${response.statusCode}');
  }

  /// Registers [device] in Datahub.
  Future<DatahubRegisterResult> registerBadgeDevice(
    BleDevice device, {
    String? apiKey,
  }) async {
    final resolvedKey = (apiKey ?? device.apiKey)?.trim();
    if (resolvedKey == null || resolvedKey.isEmpty) {
      return DatahubRegisterResult.failed;
    }

    final now = DateTime.now().toUtc();
    final time = now.toIso8601String();
    final battery = device.batteryDetails;
    final payload = <String, dynamic>{
      'device': {
        'time': time,
        'device': device.chipIdForApi,
        'firmware': device.firmwareVersion?.toString() ?? '0.0.0',
        'model': device.model.id,
        'apikey': resolvedKey,
        'battery': {
          'voltage': battery?.voltage ?? 0.0,
          'percentage': battery?.percentage ?? 0.0,
        },
      },
      'status_list': [
        {
          'time': time,
          'level': 1,
          'message': 'Registered via Luftdaten app',
        },
      ],
    };

    final body = jsonEncode(payload);
    logger.d('Datahub register POST ${_statusUri.host} device=${device.chipIdForApi}');
    final response = await _client.post(
      _statusUri,
      headers: const {'Content-Type': 'application/json'},
      body: body,
    );
    logger.d(
      'Datahub register response ${response.statusCode}'
      '${response.statusCode != 200 ? ' body=${response.body}' : ''}',
    );
    if (response.statusCode == 200) return DatahubRegisterResult.success;
    if (_isWrongApiKeyResponse(response)) return DatahubRegisterResult.wrongApiKey;
    return DatahubRegisterResult.failed;
  }

  static bool _isWrongApiKeyResponse(http.Response response) {
    if (response.statusCode != 400) return false;
    final body = response.body;
    if (body.contains('Wrong API Key')) return true;
    try {
      final decoded = jsonDecode(body);
      if (decoded is List && decoded.any((e) => e.toString().contains('Wrong API Key'))) {
        return true;
      }
      if (decoded is Map && decoded['detail']?.toString().contains('Wrong API Key') == true) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}
