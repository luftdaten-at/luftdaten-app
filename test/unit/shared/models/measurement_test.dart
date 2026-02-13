import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/shared/domain/dimensions.dart';
import 'package:luftdaten.at/shared/models/measurement.dart';

void main() {
  group('Location', () {
    test('fromJson parses lat, lon, height', () {
      final loc = Location.fromJson({
        'lat': 48.2,
        'lon': 16.4,
        'height': 200.0,
      });
      expect(loc.lat, 48.2);
      expect(loc.lon, 16.4);
      expect(loc.height, 200.0);
    });
  });

  group('Values', () {
    test('fromJson parses dimension and value', () {
      final v = Values.fromJson({'dimension': Dimension.PM2_5, 'value': 12.5});
      expect(v.dimension, Dimension.PM2_5);
      expect(v.value, 12.5);
    });
  });

  group('Measurement', () {
    test('fromJson parses full structure', () {
      final m = Measurement.fromJson({
        'location': {'lat': 48.2, 'lon': 16.4},
        'values': [
          {'dimension': Dimension.PM2_5, 'value': 10.0},
        ],
        'device': 'device-123',
        'time_measured': '2024-03-15T10:00:00Z',
      });
      expect(m.location.lat, 48.2);
      expect(m.values.length, 1);
      expect(m.values.first.dimension, Dimension.PM2_5);
      expect(m.values.first.value, 10.0);
      expect(m.deviceId, 'device-123');
    });

    test('get_valueByDimension returns value for matching dimension', () {
      final m = Measurement(
        Location(0, 0, null),
        [Values(Dimension.PM2_5, 15.0)],
        'dev',
        null,
      );
      expect(m.get_valueByDimension(Dimension.PM2_5), 15.0);
      expect(m.get_valueByDimension(Dimension.TEMPERATURE), isNull);
    });
  });
}
