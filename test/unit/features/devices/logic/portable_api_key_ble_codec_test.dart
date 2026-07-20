import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/logic/datahub_api_key_generator.dart';
import 'package:luftdaten.at/features/devices/logic/portable_api_key_ble_codec.dart';

void main() {
  group('PortableApiKeyBleCodec.encodeSetApiKeyCommand', () {
    test('encodes command 0x09 with TLV flag 20', () {
      const key = 'abcdefghijklmnopqrstuvwxyz012345';
      final bytes = PortableApiKeyBleCodec.encodeSetApiKeyCommand(key);

      expect(bytes.first, PortableApiKeyBleCodec.cmdSetPortableConfiguration);
      expect(bytes[1], AirStationConfigFlags.API_KEY.value);
      expect(bytes[2], key.length);
      expect(utf8.decode(bytes.sublist(3)), key);
    });

    test('throws when key is shorter than minLength', () {
      expect(
        () => PortableApiKeyBleCodec.encodeSetApiKeyCommand('short'),
        throwsArgumentError,
      );
    });

    test('accepts keys at exactly minLength', () {
      final key = 'a' * DatahubApiKeyGenerator.minLength;
      final bytes = PortableApiKeyBleCodec.encodeSetApiKeyCommand(key);
      expect(bytes[2], DatahubApiKeyGenerator.minLength);
    });
  });
}
