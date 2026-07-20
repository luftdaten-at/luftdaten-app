import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/latest_measurement_layout.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';

MeasurementMetricEntry _entry(MeasurableQuantity quantity) {
  return MeasurementMetricEntry(
    quantity: quantity,
    value: 1,
    sensor: LDSensor.sen5x,
    statusColor: Colors.black,
    formattedValue: '1.0',
    sensorSymbol: '',
  );
}

void main() {
  group('LatestMeasurementLayout', () {
    late List<MeasurementMetricEntry> entries;

    setUp(() {
      entries = [
        _entry(MeasurableQuantity.pm25),
        _entry(MeasurableQuantity.pm1),
        _entry(MeasurableQuantity.pm10),
        _entry(MeasurableQuantity.temperature),
        _entry(MeasurableQuantity.humidity),
        _entry(MeasurableQuantity.uva),
        _entry(MeasurableQuantity.uvb),
        _entry(MeasurableQuantity.uvc),
        _entry(MeasurableQuantity.voc),
        _entry(MeasurableQuantity.nox),
        _entry(MeasurableQuantity.co2),
      ];
    });

    test('extracts PM composite entries separately from grid', () {
      final layout = LatestMeasurementLayout.group(entries);

      expect(layout.pm25, isNotNull);
      expect(layout.pm1, isNotNull);
      expect(layout.pm10, isNotNull);
      expect(layout.hasParticulateComposite, isTrue);
      expect(
        layout.gridOthers.any((e) => e.quantity == MeasurableQuantity.pm25),
        isFalse,
      );
    });

    test('extracts temperature and humidity as climate pair', () {
      final layout = LatestMeasurementLayout.group(entries);

      expect(layout.temperature, isNotNull);
      expect(layout.humidity, isNotNull);
      expect(layout.hasClimatePair, isTrue);
      expect(
        layout.gridOthers.any((e) => e.quantity == MeasurableQuantity.temperature),
        isFalse,
      );
      expect(
        layout.gridOthers.any((e) => e.quantity == MeasurableQuantity.humidity),
        isFalse,
      );
    });

    test('extracts UV bands for composite tile and excludes them from grid', () {
      final layout = LatestMeasurementLayout.group(entries);

      expect(layout.uva, isNotNull);
      expect(layout.uvb, isNotNull);
      expect(layout.uvc, isNotNull);
      expect(layout.hasUvComposite, isTrue);
      expect(
        layout.gridOthers.any((e) => e.quantity == MeasurableQuantity.uva),
        isFalse,
      );
    });

    test('places VOC and CO2 in gridOthers', () {
      final layout = LatestMeasurementLayout.group(entries);

      expect(
        layout.gridOthers.map((e) => e.quantity),
        containsAll([
          MeasurableQuantity.voc,
          MeasurableQuantity.nox,
          MeasurableQuantity.co2,
        ]),
      );
    });

    test('maps expansion keys to chart ids', () {
      expect(
        LatestMeasurementLayout.chartIdForExpansion(
          LatestMeasurementExpansionKey.particulate,
        ),
        ChartSeriesChartId.particulate,
      );
      expect(
        LatestMeasurementLayout.chartIdForExpansion(LatestMeasurementExpansionKey.climate),
        isNull,
      );
      expect(
        LatestMeasurementLayout.chartIdForExpansion(LatestMeasurementExpansionKey.uv),
        isNull,
      );
      expect(
        LatestMeasurementLayout.chartIdForExpansion(LatestMeasurementExpansionKey.uva),
        ChartSeriesChartId.uva,
      );
      expect(
        LatestMeasurementLayout.quantityForExpansion(LatestMeasurementExpansionKey.co2),
        MeasurableQuantity.co2,
      );
    });

    test('UV metrics share a single uv expansion key', () {
      final uva = entries.firstWhere((e) => e.quantity == MeasurableQuantity.uva);
      final uvb = entries.firstWhere((e) => e.quantity == MeasurableQuantity.uvb);
      final uvc = entries.firstWhere((e) => e.quantity == MeasurableQuantity.uvc);

      expect(
        LatestMeasurementLayout.expansionKeyFor(uva),
        LatestMeasurementExpansionKey.uv,
      );
      expect(
        LatestMeasurementLayout.expansionKeyFor(uvb),
        LatestMeasurementExpansionKey.uv,
      );
      expect(
        LatestMeasurementLayout.expansionKeyFor(uvc),
        LatestMeasurementExpansionKey.uv,
      );
    });

    test('stores firmware uvi separately from UV bands', () {
      final withUvi = [
        ...entries,
        _entry(MeasurableQuantity.uvi),
      ];
      final layout = LatestMeasurementLayout.group(withUvi);

      expect(layout.firmwareUvi, isNotNull);
      expect(layout.hasUvComposite, isTrue);
    });
  });
}
