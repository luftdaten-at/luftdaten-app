import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/light_metrics.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';

MeasurementMetricEntry _entry(MeasurableQuantity quantity, double value) {
  return MeasurementMetricEntry(
    quantity: quantity,
    value: value,
    sensor: LDSensor.tsl2591,
    statusColor: Colors.black,
    formattedValue: value.toString(),
    sensorSymbol: '',
  );
}

void main() {
  group('LightMetrics.irSharePercent', () {
    test('returns null when infrared is missing', () {
      expect(
        LightMetrics.irSharePercent(
          infrared: null,
          fullSpectrum: 1000,
          visible: 800,
        ),
        isNull,
      );
    });

    test('returns null when denominator is zero', () {
      expect(
        LightMetrics.irSharePercent(
          infrared: 100,
          fullSpectrum: 0,
          visible: 0,
        ),
        isNull,
      );
    });

    test('computes from full spectrum when present', () {
      expect(
        LightMetrics.irSharePercent(
          infrared: 200,
          fullSpectrum: 1000,
          visible: 800,
        ),
        closeTo(20, 0.001),
      );
    });

    test('falls back to visible + infrared when full spectrum is missing', () {
      expect(
        LightMetrics.irSharePercent(
          infrared: 200,
          fullSpectrum: null,
          visible: 800,
        ),
        closeTo(20, 0.001),
      );
    });
  });

  group('LightMetrics.heroFromEntries', () {
    test('formats lux hero and IR share side rows', () {
      final snapshot = LightMetrics.heroFromEntries(
        lux: _entry(MeasurableQuantity.lux, 123.4),
        visible: _entry(MeasurableQuantity.visible, 800),
        infrared: _entry(MeasurableQuantity.infrared, 200),
        fullSpectrum: _entry(MeasurableQuantity.fullSpectrum, 1000),
      );

      expect(snapshot.heroValue, 123.4);
      expect(snapshot.heroFormatted, '123.4');
      expect(snapshot.irSharePercent, closeTo(20, 0.001));
      expect(snapshot.irShareFormatted, '20.0 %');
      expect(snapshot.hasAnyChannel, isTrue);
    });

    test('shows dash when lux is missing', () {
      final snapshot = LightMetrics.heroFromEntries(
        lux: null,
        visible: _entry(MeasurableQuantity.visible, 800),
        infrared: _entry(MeasurableQuantity.infrared, 200),
        fullSpectrum: null,
      );

      expect(snapshot.heroFormatted, '-');
      expect(snapshot.irSharePercent, closeTo(20, 0.001));
    });
  });

  group('LightMetrics.luxSparklineFromHistory', () {
    test('includes points with lux and skips points without lux', () {
      final history = [
        MeasuredDataPoint(
          timestamp: DateTime(2026, 1, 1, 12),
          sensorData: [
            SensorDataPoint(
              sensor: LDSensor.tsl2591,
              values: {
                MeasurableQuantity.lux: 100,
                MeasurableQuantity.visible: 800,
              },
            ),
          ],
        ),
        MeasuredDataPoint(
          timestamp: DateTime(2026, 1, 1, 12, 1),
          sensorData: [
            SensorDataPoint(
              sensor: LDSensor.tsl2591,
              values: {
                MeasurableQuantity.visible: 900,
              },
            ),
          ],
        ),
        MeasuredDataPoint(
          timestamp: DateTime(2026, 1, 1, 12, 2),
          sensorData: [
            SensorDataPoint(
              sensor: LDSensor.tsl2591,
              values: {
                MeasurableQuantity.lux: 150,
              },
            ),
          ],
        ),
      ];

      final points = LightMetrics.luxSparklineFromHistory(history: history);
      expect(points, hasLength(2));
      expect(points.first.value, 100);
      expect(points.last.value, 150);
    });
  });
}
