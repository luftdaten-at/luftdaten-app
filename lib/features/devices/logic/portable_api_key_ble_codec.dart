import 'dart:convert';

import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/logic/datahub_api_key_generator.dart';

/// BLE command `0x09` (`SET_PORTABLE_CONFIGURATION`) with TLV flag `20` (`API_KEY`).
abstract final class PortableApiKeyBleCodec {
  static const int cmdSetPortableConfiguration = 0x09;

  /// `[0x09][flag 20][len u8][api_key UTF-8]`
  static List<int> encodeSetApiKeyCommand(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.length < DatahubApiKeyGenerator.minLength) {
      throw ArgumentError.value(
        apiKey,
        'apiKey',
        'must be at least ${DatahubApiKeyGenerator.minLength} characters',
      );
    }
    final bytes = utf8.encode(trimmed);
    if (bytes.length > 255) {
      throw ArgumentError.value(apiKey, 'apiKey', 'UTF-8 length must be at most 255');
    }
    return [
      cmdSetPortableConfiguration,
      AirStationConfigFlags.API_KEY.value,
      bytes.length,
      ...bytes,
    ];
  }
}
