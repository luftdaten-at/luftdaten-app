import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurement/models/measured_data.dart';

void main() {
  group('LDSensor', () {
    test('fromId returns sensor for known id', () {
      expect(LDSensor.fromId(1), LDSensor.sen5x);
      expect(LDSensor.fromId(2), LDSensor.bmp280);
    });

    test('fromId returns unknown for invalid id', () {
      expect(LDSensor.fromId(999), LDSensor.unknown);
    });

    test('fromName returns sensor for known name', () {
      expect(LDSensor.fromName('sen5x'), LDSensor.sen5x);
    });
  });

  group('MeasurableQuantity', () {
    test('fromId returns quantity for known id', () {
      expect(MeasurableQuantity.fromId(3), MeasurableQuantity.pm25);
    });

    test('fromId returns unknown for invalid id', () {
      expect(MeasurableQuantity.fromId(999), MeasurableQuantity.unknown);
    });
  });

  group('SensorDataPoint', () {
    test('fromJson parses sensor and values', () {
      // JSON keys use quantity.name (_name.i18n). PM2.5 works; locale may affect other keys.
      final sp = SensorDataPoint.fromJson({
        'sensor': 'sen5x',
        'PM2.5': 10.5,
      });
      expect(sp.sensor, LDSensor.sen5x);
      expect(sp.values[MeasurableQuantity.pm25], 10.5);
      expect(sp.values.length, greaterThanOrEqualTo(1));
    });
  });
}
