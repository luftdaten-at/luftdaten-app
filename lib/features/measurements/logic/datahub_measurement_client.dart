import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';

/// POSTs firmware-style measurement JSON (`device` + `sensors`) to Datahub.
///
/// Same host and path as workshop uploads; payload shape matches SD JSONL /
/// [`get_json()`] from firmware (see `docs/api-json.md` in luftdaten-at/firmware).
class DatahubMeasurementClient {
  DatahubMeasurementClient();

  String get _serverHost =>
      AppSettings.I.useStagingServer ? 'staging.datahub.luftdaten.at' : 'datahub.luftdaten.at';

  Uri get _dataUrl => Uri.parse('https://$_serverHost/api/v1/devices/data/');

  /// POST one measurement object; returns HTTP status (200 = OK).
  Future<int> postFirmwareStyleMeasurement(Map<String, dynamic> json) async {
    final body = jsonEncode(json);
    logger.d('Datahub POST ${_dataUrl.host} (len=${body.length})');
    final res = await http.post(
      _dataUrl,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    logger.d('Datahub response ${res.statusCode}');
    return res.statusCode;
  }
}
