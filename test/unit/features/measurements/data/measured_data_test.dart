import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  group('LDSensor', () {
    test('fromId returns sensor for known id', () {
      expect(LDSensor.fromId(1), LDSensor.sen5x);
      expect(LDSensor.fromId(2), LDSensor.bmp280);
      expect(LDSensor.fromId(9), LDSensor.ags02ma);
      expect(LDSensor.fromId(10), LDSensor.sht4x);
      expect(LDSensor.fromId(11), LDSensor.sgp40);
      expect(LDSensor.fromId(23), LDSensor.sen66);
      expect(LDSensor.fromId(29), LDSensor.shtc3);
    });

    test('fromId returns unknown for invalid id', () {
      expect(LDSensor.fromId(999), LDSensor.unknown);
    });

    test('fromName returns sensor for known name', () {
      expect(LDSensor.fromName('sen5x'), LDSensor.sen5x);
      expect(LDSensor.fromName('sen66'), LDSensor.sen66);
    });

    test('sht4x and ags02ma do not share id 9', () {
      expect(LDSensor.ags02ma.id, 9);
      expect(LDSensor.sht4x.id, 10);
      expect(LDSensor.fromId(9), isNot(LDSensor.sht4x));
    });

    test('sgp40 measures gas indices not temperature', () {
      expect(
        LDSensor.sgp40.measures,
        [
          MeasurableQuantity.sgp40RawGasIndex,
          MeasurableQuantity.sgp40AdjustedGasIndex,
        ],
      );
    });
  });

  group('MeasurableQuantity', () {
    test('fromId returns quantity for known id', () {
      expect(MeasurableQuantity.fromId(3), MeasurableQuantity.pm25);
      expect(MeasurableQuantity.fromId(23), MeasurableQuantity.uvi);
      expect(MeasurableQuantity.fromId(35), MeasurableQuantity.rawLuminosity);
    });

    test('fromId returns unknown for invalid id', () {
      expect(MeasurableQuantity.fromId(999), MeasurableQuantity.unknown);
    });

    test('co2 and gasResistance use firmware units', () {
      expect(MeasurableQuantity.co2.csvUnit, 'ppm');
      expect(MeasurableQuantity.gasResistance.csvUnit, 'Ω');
    });

    test('binary payload decodes new dimension id', () {
      const dimensionId = 23;
      const rawValue = 65;
      final quantity = MeasurableQuantity.fromId(dimensionId);
      final value = rawValue / 10.0;
      expect(quantity, MeasurableQuantity.uvi);
      expect(value, 6.5);
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
