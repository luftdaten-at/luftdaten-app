import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/data/sensor_data.dart';

void main() {
  group('Location', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'longitude': 16.37,
        'latitude': 48.21,
        'altitude': 180.0,
      };
      final location = Location.fromJson(json);
      final restored = location.toJson();
      expect(restored['longitude'], 16.37);
      expect(restored['latitude'], 48.21);
      expect(restored['altitude'], 180.0);
    });
  });

  group('SensorDataValue', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 123,
        'value_type': 'P2',
        'value': '12.5',
      };
      final value = SensorDataValue.fromJson(json);
      expect(value.id, 123);
      expect(value.value_type, 'P2');
      expect(value.value, '12.5');
      final restored = value.toJson();
      expect(restored['value_type'], 'P2');
    });
  });

  group('SensorType', () {
    test('fromJson parses fields', () {
      final json = {
        'id': 14,
        'manufacturer': 'Sensirion',
        'name': 'SEN5x',
      };
      final type = SensorType.fromJson(json);
      expect(type.id, 14);
      expect(type.manufacturer, 'Sensirion');
      expect(type.name, 'SEN5x');
    });
  });

  group('Sensor', () {
    test('fromJson parses with sensor_type', () {
      final json = {
        'id': 1,
        'sensor_type': {
          'id': 14,
          'manufacturer': 'Sensirion',
          'name': 'SEN5x',
        },
      };
      final sensor = Sensor.fromJson(json);
      expect(sensor.id, 1);
      expect(sensor.sensor_type.name, 'SEN5x');
    });
  });

  group('SCData', () {
    test('fromJson parses full structure', () {
      final json = {
        'timestamp': '2024-01-15T10:00:00.000Z',
        'location': {
          'longitude': 16.37,
          'latitude': 48.21,
          'altitude': 180.0,
        },
        'sensordatavalues': [
          {'id': 1, 'value_type': 'P2', 'value': '10.0'},
        ],
        'sensor': {
          'id': 1,
          'sensor_type': {
            'id': 14,
            'manufacturer': 'Sensirion',
            'name': 'SEN5x',
          },
        },
      };
      final data = SCData.fromJson(json);
      expect(data.timestamp, DateTime.utc(2024, 1, 15, 10));
      expect(data.location.latitude, 48.21);
      expect(data.sensordatavalues.length, 1);
      expect(data.sensordatavalues.first.value_type, 'P2');
      expect(data.sensor.sensor_type.name, 'SEN5x');
    });
  });
}
