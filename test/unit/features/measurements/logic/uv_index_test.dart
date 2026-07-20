import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/uv_index.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';

MeasurementMetricEntry _entry(MeasurableQuantity quantity, double value) {
  return MeasurementMetricEntry(
    quantity: quantity,
    value: value,
    sensor: LDSensor.as7331,
    statusColor: Colors.black,
    formattedValue: value.toString(),
    sensorSymbol: '',
  );
}

void main() {
  group('UvIndex.computeFromIrradiance', () {
    test('returns null when both bands are missing', () {
      expect(
        UvIndex.computeFromIrradiance(uva: null, uvb: null),
        isNull,
      );
    });

    test('computes broadband UVI from UVA and UVB', () {
      // UVE = 0.17*100 + 0.83*50 = 17 + 41.5 = 58.5
      // UVI = 0.4 * 58.5 = 23.4
      expect(
        UvIndex.computeFromIrradiance(uva: 100, uvb: 50),
        closeTo(23.4, 0.001),
      );
    });

    test('uses zero for missing single band', () {
      expect(
        UvIndex.computeFromIrradiance(uva: 100, uvb: null),
        closeTo(0.4 * 0.17 * 100, 0.001),
      );
    });
  });

  group('UvIndex.resolveHeroValue', () {
    test('prefers firmware uvi over computed value', () {
      expect(
        UvIndex.resolveHeroValue(firmwareUvi: 7.5, uva: 100, uvb: 50),
        7.5,
      );
    });

    test('falls back to computed value when firmware uvi is absent', () {
      expect(
        UvIndex.resolveHeroValue(firmwareUvi: null, uva: 100, uvb: 50),
        closeTo(23.4, 0.001),
      );
    });
  });

  group('UvIndex.heroFromEntries', () {
    test('uses firmware uvi for hero when present', () {
      final snapshot = UvIndex.heroFromEntries(
        uva: _entry(MeasurableQuantity.uva, 100),
        uvb: _entry(MeasurableQuantity.uvb, 50),
        uvc: null,
        firmwareUvi: _entry(MeasurableQuantity.uvi, 8.2),
      );

      expect(snapshot.heroValue, 8.2);
      expect(snapshot.heroFormatted, '8.2');
    });

    test('computes hero from bands when firmware uvi is absent', () {
      final snapshot = UvIndex.heroFromEntries(
        uva: _entry(MeasurableQuantity.uva, 100),
        uvb: _entry(MeasurableQuantity.uvb, 50),
        uvc: _entry(MeasurableQuantity.uvc, 10),
        firmwareUvi: null,
      );

      expect(snapshot.heroValue, closeTo(23.4, 0.001));
    });
  });

  group('UvIndex.sparklineFromHistory', () {
    test('prefers firmware uvi per history point', () {
      final history = [
        MeasuredDataPoint(
          timestamp: DateTime(2026, 1, 1, 12),
          sensorData: [
            SensorDataPoint(
              sensor: LDSensor.as7331,
              values: {
                MeasurableQuantity.uva: 100,
                MeasurableQuantity.uvb: 50,
                MeasurableQuantity.uvi: 6.0,
              },
            ),
          ],
        ),
      ];

      final points = UvIndex.sparklineFromHistory(history: history);
      expect(points, hasLength(1));
      expect(points.first.value, 6.0);
    });

    test('computes from bands when firmware uvi is absent', () {
      final history = [
        MeasuredDataPoint(
          timestamp: DateTime(2026, 1, 1, 12),
          sensorData: [
            SensorDataPoint(
              sensor: LDSensor.as7331,
              values: {
                MeasurableQuantity.uva: 100,
                MeasurableQuantity.uvb: 50,
              },
            ),
          ],
        ),
      ];

      final points = UvIndex.sparklineFromHistory(history: history);
      expect(points, hasLength(1));
      expect(points.first.value, closeTo(23.4, 0.001));
    });
  });
}
