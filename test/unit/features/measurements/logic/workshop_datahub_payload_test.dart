import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/data/latlng_with_precision.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/workshop_datahub_payload.dart';
import 'package:luftdaten.at/features/devices/logic/ble_json_parser.dart';

void main() {
  MeasuredDataPoint samplePoint({
    LatLngWithPrecision? location,
    Map<String, dynamic>? j,
  }) {
    return MeasuredDataPoint(
      timestamp: DateTime.utc(2025, 1, 7, 11, 23, 23),
      sensorData: [
        SensorDataPoint(
          sensor: LDSensor.sen5x,
          values: {MeasurableQuantity.pm25: 12.5},
        ),
      ],
      location: location,
      mode: MobilityModes.walking,
      j: j,
    );
  }

  group('WorkshopDatahubPayload.build', () {
    test('includes workshop, location, device, and sensors', () {
      final payload = WorkshopDatahubPayload.build(
        dataPoint: samplePoint(
          location: LatLngWithPrecision(48.1769523, 16.3654834, null),
        ),
        deviceChipId: 'D83BDA6E37DDAAA',
        deviceModelId: 1,
        firmware: '2.0.0',
        workshopId: 'homrh8',
        apikey: 'test-key',
        participant: '8133a310-ffaf-11f0-8794-bbb756d19a96',
      );

      expect(payload, isNotNull);
      expect(payload!['workshop'], {
        'id': 'homrh8',
        'participant': '8133a310-ffaf-11f0-8794-bbb756d19a96',
        'mode': 'walking',
      });
      expect(payload['location'], {'lat': 48.1769523, 'lon': 16.3654834});
      final device = payload['device'] as Map<String, dynamic>;
      expect(device['id'], 'D83BDA6E37DDAAA');
      expect(device['apikey'], 'test-key');
      expect(payload['sensors'], isNotEmpty);
    });

    test('returns null when location is missing', () {
      final payload = WorkshopDatahubPayload.build(
        dataPoint: samplePoint(),
        deviceChipId: 'D83BDA6E37DDAAA',
        deviceModelId: 1,
        firmware: '2.0.0',
        workshopId: 'homrh8',
        apikey: 'test-key',
        participant: 'uid',
      );
      expect(payload, isNull);
    });

    test('uses lat/lon not GeoJSON coordinates', () {
      final payload = WorkshopDatahubPayload.build(
        dataPoint: samplePoint(
          location: LatLngWithPrecision(48.2, 16.4, 5.0),
        ),
        deviceChipId: 'dev',
        deviceModelId: 1,
        firmware: '1.0.0',
        workshopId: 'abc123',
        apikey: 'k',
        participant: 'p',
      );
      final loc = payload!['location'] as Map<String, dynamic>;
      expect(loc.containsKey('lat'), isTrue);
      expect(loc.containsKey('lon'), isTrue);
      expect(loc.containsKey('coordinates'), isFalse);
    });

    test('merges firmware-style j and still adds workshop and location', () {
      final j = <String, dynamic>{
        'device': {
          'time': '2025-01-01T00:00:00Z',
          'device': 'OLDID',
          'firmware': '1.0',
          'model': 1,
          'apikey': 'from-j',
        },
        'sensors': {
          '1': {'type': 1, 'data': {'3': 6.0}},
        },
      };
      final payload = WorkshopDatahubPayload.build(
        dataPoint: samplePoint(
          location: LatLngWithPrecision(48.0, 16.0, null),
          j: j,
        ),
        deviceChipId: 'NEWID',
        deviceModelId: 2,
        firmware: '2.0.0',
        workshopId: 'homrh8',
        apikey: 'app-key',
        participant: 'participant-1',
      );

      expect(payload, isNotNull);
      expect(payload!['workshop']['id'], 'homrh8');
      expect(payload['location'], {'lat': 48.0, 'lon': 16.0});
      final device = payload['device'] as Map<String, dynamic>;
      expect(device['id'], 'NEWID');
      expect(device['apikey'], 'app-key');
      expect(payload.containsKey('station'), isFalse);
    });
  });

  group('BleJsonParser.parseApiKey device block', () {
    test('extracts from device.api.key', () {
      expect(
        BleJsonParser.parseApiKey({
          'device': {
            'api': {'key': 'portable-key'},
          },
        }),
        'portable-key',
      );
    });
  });
}
