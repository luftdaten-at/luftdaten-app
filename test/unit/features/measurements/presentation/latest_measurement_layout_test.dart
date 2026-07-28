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

    test('extracts light composite entries and excludes them from grid', () {
      final lightEntries = [
        ...entries,
        _entry(MeasurableQuantity.lux),
        _entry(MeasurableQuantity.visible),
        _entry(MeasurableQuantity.infrared),
        _entry(MeasurableQuantity.fullSpectrum),
        _entry(MeasurableQuantity.rawLuminosity),
      ];
      final layout = LatestMeasurementLayout.group(lightEntries);

      expect(layout.lux, isNotNull);
      expect(layout.visibleLight, isNotNull);
      expect(layout.infrared, isNotNull);
      expect(layout.fullSpectrum, isNotNull);
      expect(layout.hasLightComposite, isTrue);
      expect(
        layout.gridOthers.any((e) => e.quantity == MeasurableQuantity.lux),
        isFalse,
      );
      expect(
        layout.gridOthers.any((e) => e.quantity == MeasurableQuantity.visible),
        isFalse,
      );
      expect(
        layout.gridOthers.any((e) => e.quantity == MeasurableQuantity.infrared),
        isFalse,
      );
      expect(
        layout.gridOthers.any((e) => e.quantity == MeasurableQuantity.fullSpectrum),
        isFalse,
      );
      expect(
        layout.gridOthers.any((e) => e.quantity == MeasurableQuantity.rawLuminosity),
        isFalse,
      );
    });

    test('light metrics share a single light expansion key', () {
      final lux = _entry(MeasurableQuantity.lux);
      final visible = _entry(MeasurableQuantity.visible);
      final infrared = _entry(MeasurableQuantity.infrared);

      expect(
        LatestMeasurementLayout.expansionKeyFor(lux),
        LatestMeasurementExpansionKey.light,
      );
      expect(
        LatestMeasurementLayout.expansionKeyFor(visible),
        LatestMeasurementExpansionKey.light,
      );
      expect(
        LatestMeasurementLayout.expansionKeyFor(infrared),
        LatestMeasurementExpansionKey.light,
      );
    });

    test('indoor/outdoor detection needs both illuminance and UV bands', () {
      // entries carry the UV bands but no lux.
      expect(LatestMeasurementLayout.group(entries).hasEnvironmentContext, isFalse);

      expect(
        LatestMeasurementLayout.group([
          _entry(MeasurableQuantity.lux),
          _entry(MeasurableQuantity.visible),
        ]).hasEnvironmentContext,
        isFalse,
      );

      expect(
        LatestMeasurementLayout.group([
          ...entries,
          _entry(MeasurableQuantity.lux),
        ]).hasEnvironmentContext,
        isTrue,
      );
    });

    test('the environment tile owns its charts instead of the grid builder', () {
      expect(
        LatestMeasurementLayout.chartIdForExpansion(
          LatestMeasurementExpansionKey.environment,
        ),
        isNull,
      );
      expect(
        LatestMeasurementLayout.quantityForExpansion(
          LatestMeasurementExpansionKey.environment,
        ),
        isNull,
      );
    });

    test('thermal comfort needs temperature and humidity', () {
      expect(LatestMeasurementLayout.group(entries).hasThermalComfort, isTrue);
      expect(
        LatestMeasurementLayout.group([
          _entry(MeasurableQuantity.temperature),
        ]).hasThermalComfort,
        isFalse,
      );
    });

    test('the thermal tile owns its charts instead of the grid builder', () {
      expect(
        LatestMeasurementLayout.chartIdForExpansion(
          LatestMeasurementExpansionKey.thermal,
        ),
        isNull,
      );
    });

    test('availableTiles lists composite sections present in layout', () {
      final layout = LatestMeasurementLayout.group([
        ...entries,
        _entry(MeasurableQuantity.lux),
      ]);

      expect(
        LatestMeasurementLayout.availableTiles(
          layout,
          showBattery: false,
          hasBattery: false,
        ),
        [
          MeasurementTileId.particulate,
          MeasurementTileId.climate,
          MeasurementTileId.uv,
          MeasurementTileId.light,
          MeasurementTileId.environment,
          MeasurementTileId.thermal,
          MeasurementTileId.others,
        ],
      );
    });

    test('availableTiles includes others when battery is shown', () {
      final layout = LatestMeasurementLayout.group([
        _entry(MeasurableQuantity.co2),
      ]);

      expect(
        LatestMeasurementLayout.availableTiles(
          layout,
          showBattery: true,
          hasBattery: true,
        ),
        [MeasurementTileId.others],
      );
    });
  });
}
