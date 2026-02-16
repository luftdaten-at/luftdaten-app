import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_json_parser.dart';

void main() {
  group('BleJsonParser.parseApiKey', () {
    test('returns null for null input', () {
      expect(BleJsonParser.parseApiKey(null), isNull);
    });

    test('returns null for empty map', () {
      expect(BleJsonParser.parseApiKey({}), isNull);
    });

    test('extracts from station.api.key', () {
      expect(
        BleJsonParser.parseApiKey({
          'station': {'api': {'key': 'my-api-key'}},
        }),
        'my-api-key',
      );
    });

    test('extracts from station.apikey', () {
      expect(
        BleJsonParser.parseApiKey({
          'station': {'apikey': 'station-apikey'},
        }),
        'station-apikey',
      );
    });

    test('prefers station.api.key over station.apikey', () {
      expect(
        BleJsonParser.parseApiKey({
          'station': {
            'api': {'key': 'preferred'},
            'apikey': 'fallback',
          },
        }),
        'preferred',
      );
    });

    test('extracts from top-level apikey', () {
      expect(
        BleJsonParser.parseApiKey({'apikey': 'top-level'}),
        'top-level',
      );
    });

    test('returns null for empty string apikey', () {
      expect(BleJsonParser.parseApiKey({'apikey': ''}), isNull);
      expect(BleJsonParser.parseApiKey({'station': {'apikey': ''}}), isNull);
    });

    test('returns null when station is not a Map', () {
      expect(BleJsonParser.parseApiKey({'station': 'not-a-map'}), isNull);
    });
  });

  group('BleJsonParser.parseFirmwareFromStation', () {
    test('returns null for null input', () {
      expect(BleJsonParser.parseFirmwareFromStation(null), isNull);
    });

    test('parses "1.5" to FirmwareVersion(1, 5, 0)', () {
      final result = BleJsonParser.parseFirmwareFromStation({'firmware': '1.5'});
      expect(result, isNotNull);
      expect(result!.major, 1);
      expect(result.minor, 5);
      expect(result.patch, 0);
    });

    test('parses "1.5.14" to full version', () {
      final result =
          BleJsonParser.parseFirmwareFromStation({'firmware': '1.5.14'});
      expect(result, isNotNull);
      expect(result!.major, 1);
      expect(result.minor, 5);
      expect(result.patch, 14);
    });

    test('parses "2.0" to (2, 0, 0)', () {
      final result = BleJsonParser.parseFirmwareFromStation({'firmware': '2.0'});
      expect(result, isNotNull);
      expect(result!.major, 2);
      expect(result.minor, 0);
      expect(result.patch, 0);
    });

    test('returns null when firmware is not a string', () {
      expect(
        BleJsonParser.parseFirmwareFromStation({'firmware': 123}),
        isNull,
      );
      expect(
        BleJsonParser.parseFirmwareFromStation({'firmware': null}),
        isNull,
      );
    });

    test('returns null when firmware is missing', () {
      expect(BleJsonParser.parseFirmwareFromStation({}), isNull);
    });

    test('handles invalid number parts with 0 fallback', () {
      final result =
          BleJsonParser.parseFirmwareFromStation({'firmware': 'x.y.z'});
      expect(result, isNotNull);
      expect(result!.major, 0);
      expect(result.minor, 0);
      expect(result.patch, 0);
    });
  });
}
