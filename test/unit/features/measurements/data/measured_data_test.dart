import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/data/environment_context_reading.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/thermal_comfort_reading.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_bands.dart';
import 'package:luftdaten.at/features/weather/data/weather_snapshot.dart';

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
      expect(LDSensor.fromId(30), LDSensor.as7331);
      expect(LDSensor.fromId(31), LDSensor.bmv080);
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

    test('as7331 measures UVA UVB UVC', () {
      expect(LDSensor.as7331.id, 30);
      expect(
        LDSensor.as7331.measures,
        [
          MeasurableQuantity.uva,
          MeasurableQuantity.uvb,
          MeasurableQuantity.uvc,
        ],
      );
    });

    test('bmv080 measures PM1 PM25 PM10', () {
      expect(LDSensor.bmv080.id, 31);
      expect(
        LDSensor.bmv080.measures,
        [
          MeasurableQuantity.pm1,
          MeasurableQuantity.pm25,
          MeasurableQuantity.pm10,
        ],
      );
    });
  });

  group('MeasurableQuantity', () {
    test('fromId returns quantity for known id', () {
      expect(MeasurableQuantity.fromId(3), MeasurableQuantity.pm25);
      expect(MeasurableQuantity.fromId(23), MeasurableQuantity.uvi);
      expect(MeasurableQuantity.fromId(35), MeasurableQuantity.rawLuminosity);
      expect(MeasurableQuantity.fromId(36), MeasurableQuantity.uva);
      expect(MeasurableQuantity.fromId(37), MeasurableQuantity.uvb);
      expect(MeasurableQuantity.fromId(38), MeasurableQuantity.uvc);
    });

    test('fromId returns unknown for invalid id', () {
      expect(MeasurableQuantity.fromId(999), MeasurableQuantity.unknown);
    });

    test('co2 and gasResistance use firmware units', () {
      expect(MeasurableQuantity.co2.csvUnit, 'ppm');
      expect(MeasurableQuantity.gasResistance.csvUnit, 'Ω');
    });

    test('uva uvb uvc use µW/cm² unit', () {
      expect(MeasurableQuantity.uva.csvUnit, 'µW/cm²');
      expect(MeasurableQuantity.uvb.csvUnit, 'µW/cm²');
      expect(MeasurableQuantity.uvc.csvUnit, 'µW/cm²');
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

  group('EnvironmentContextReading', () {
    test('round-trips through JSON including flags', () {
      const reading = EnvironmentContextReading(
        state: EnvironmentContextState.indoorWindow,
        score: -0.25,
        confidence: 1,
        saturated: true,
        uvcAnomaly: true,
      );

      final restored = EnvironmentContextReading.fromJson(reading.toJson());

      expect(restored.state, EnvironmentContextState.indoorWindow);
      expect(restored.score, -0.25);
      expect(restored.confidence, 1);
      expect(restored.saturated, isTrue);
      expect(restored.uvcAnomaly, isTrue);
    });

    test('omits flags when none are set', () {
      const reading = EnvironmentContextReading(
        state: EnvironmentContextState.indoor,
        score: -0.6,
        confidence: 0.6,
      );

      expect(reading.toJson().containsKey('flags'), isFalse);
    });

    test('an unknown state name degrades to unknown', () {
      final restored = EnvironmentContextReading.fromJson({'state': 'somewhere_else'});
      expect(restored.state, EnvironmentContextState.unknown);
    });
  });

  group('MeasuredDataPoint with a classification', () {
    MeasuredDataPoint point({EnvironmentContextReading? environment}) {
      return MeasuredDataPoint(
        timestamp: DateTime.utc(2026, 1, 1, 12),
        sensorData: [
          SensorDataPoint(
            sensor: LDSensor.tsl2591,
            values: {MeasurableQuantity.lux: 1234.5},
          ),
        ],
        environment: environment,
      );
    }

    test('round-trips the classification through JSON', () {
      final original = point(
        environment: const EnvironmentContextReading(
          state: EnvironmentContextState.outdoor,
          score: 0.81,
          confidence: 0.81,
        ),
      );

      final restored = MeasuredDataPoint.fromJson(original.toJson());

      expect(restored.environment!.state, EnvironmentContextState.outdoor);
      expect(restored.environment!.score, 0.81);
    });

    test('omits the classification when there is none', () {
      expect(point().toJson().containsKey('environment'), isFalse);
      expect(MeasuredDataPoint.fromJson(point().toJson()).environment, isNull);
    });

    test('exports classification rows marked as derived in CSV', () {
      final rows = point(
        environment: const EnvironmentContextReading(
          state: EnvironmentContextState.outdoor,
          score: 0.5,
          confidence: 0.5,
          saturated: true,
        ),
      ).toCsv();

      final derived = rows.where((e) => e.contains(',environment,')).toList();
      expect(derived, hasLength(4));
      expect(derived[0], endsWith('environment,Indoor/Outdoor,,outdoor'));
      expect(derived[3], endsWith('environment,Indoor/Outdoor Flags,,saturated'));
      // Sensor readings are still exported unchanged.
      expect(rows.any((e) => e.contains(',tsl2591,')), isTrue);
    });

    test('adds no CSV rows without a classification', () {
      expect(point().toCsv().any((e) => e.contains(',environment,')), isFalse);
    });
  });

  group('MeasuredDataPoint with thermal comfort', () {
    final weather = WeatherSnapshot(
      observedAt: DateTime.utc(2026, 7, 28, 15, 30),
      fetchedAt: DateTime.utc(2026, 7, 28, 15, 31),
      latitude: 48.21,
      longitude: 16.37,
      v10Ms: 2.2,
      v10Source: 'tawes',
    );

    final thermal = ThermalComfortReading(
      model: 'utci',
      quality: ThermalComfortQuality.a,
      utciC: 32.1,
      tMrtC: 45.2,
      fSun: 0.85,
      v10Ms: 1.1,
      tAirC: 28.5,
      computedAt: DateTime.utc(2026, 7, 28, 15, 30),
    );

    test('round-trips weather and thermal through JSON', () {
      final original = MeasuredDataPoint(
        timestamp: DateTime.utc(2026, 1, 1, 12),
        sensorData: const [
          SensorDataPoint(sensor: LDSensor.shtc3, values: {}),
        ],
        weather: weather,
        thermal: thermal,
      );

      final restored = MeasuredDataPoint.fromJson(original.toJson());
      expect(restored.weather!.v10Ms, 2.2);
      expect(restored.thermal!.utciC, 32.1);
    });

    test('exports thermal rows in CSV', () {
      final rows = MeasuredDataPoint(
        timestamp: DateTime.utc(2026, 1, 1, 12),
        sensorData: const [
          SensorDataPoint(sensor: LDSensor.shtc3, values: {}),
        ],
        thermal: thermal,
      ).toCsv();

      expect(rows.any((e) => e.contains(',thermal,UTCI,')), isTrue);
    });
  });
}
