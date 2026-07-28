import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';

enum MeasurementTileId {
  particulate,
  climate,
  uv,
  light,
  environment,
  thermal,
  others,
}

enum LatestMeasurementExpansionKey {
  particulate,
  climate,
  uv,
  light,
  environment,
  thermal,
  uva,
  uvb,
  uvc,
  voc,
  totalVoc,
  nox,
  pressure,
  co2,
  o3,
  aqi,
  gasResistance,
  batteryPercentage,
  batteryVoltage,
}

class LatestMeasurementLayoutResult {
  const LatestMeasurementLayoutResult({
    required this.temperature,
    required this.humidity,
    required this.pm25,
    required this.pm1,
    required this.pm10,
    required this.uva,
    required this.uvb,
    required this.uvc,
    required this.firmwareUvi,
    required this.lux,
    required this.visibleLight,
    required this.infrared,
    required this.fullSpectrum,
    required this.gridOthers,
  });

  final MeasurementMetricEntry? temperature;
  final MeasurementMetricEntry? humidity;
  final MeasurementMetricEntry? pm25;
  final MeasurementMetricEntry? pm1;
  final MeasurementMetricEntry? pm10;
  final MeasurementMetricEntry? uva;
  final MeasurementMetricEntry? uvb;
  final MeasurementMetricEntry? uvc;
  final MeasurementMetricEntry? firmwareUvi;
  final MeasurementMetricEntry? lux;
  final MeasurementMetricEntry? visibleLight;
  final MeasurementMetricEntry? infrared;
  final MeasurementMetricEntry? fullSpectrum;
  final List<MeasurementMetricEntry> gridOthers;

  bool get hasClimatePair => temperature != null || humidity != null;

  bool get hasParticulateComposite => pm25 != null || pm1 != null || pm10 != null;

  bool get hasUvComposite =>
      uva != null || uvb != null || uvc != null || firmwareUvi != null;

  bool get hasLightComposite =>
      lux != null || visibleLight != null || infrared != null;

  /// Indoor/outdoor detection needs both the TSL2591 illuminance and the AS7331
  /// UV bands; the ratios it builds are meaningless with only one of them.
  bool get hasEnvironmentContext => lux != null && uva != null;

  /// UTCI/PMV needs at least temperature and humidity from the climate sensor.
  bool get hasThermalComfort => temperature != null && humidity != null;
}

class LatestMeasurementLayout {
  LatestMeasurementLayout._();

  static const _compositePmQuantities = {
    MeasurableQuantity.pm1,
    MeasurableQuantity.pm25,
    MeasurableQuantity.pm10,
  };

  static const _uvBandQuantities = {
    MeasurableQuantity.uva,
    MeasurableQuantity.uvb,
    MeasurableQuantity.uvc,
  };

  static const _lightQuantities = {
    MeasurableQuantity.lux,
    MeasurableQuantity.visible,
    MeasurableQuantity.infrared,
    MeasurableQuantity.fullSpectrum,
    MeasurableQuantity.rawLuminosity,
  };

  static const _otherPmQuantities = {
    MeasurableQuantity.pm01,
    MeasurableQuantity.pm4,
  };

  static LatestMeasurementLayoutResult group(List<MeasurementMetricEntry> entries) {
    MeasurementMetricEntry? temperature;
    MeasurementMetricEntry? humidity;
    MeasurementMetricEntry? pm25;
    MeasurementMetricEntry? pm1;
    MeasurementMetricEntry? pm10;
    MeasurementMetricEntry? uva;
    MeasurementMetricEntry? uvb;
    MeasurementMetricEntry? uvc;
    MeasurementMetricEntry? firmwareUvi;
    MeasurementMetricEntry? lux;
    MeasurementMetricEntry? visibleLight;
    MeasurementMetricEntry? infrared;
    MeasurementMetricEntry? fullSpectrum;
    final gridOthers = <MeasurementMetricEntry>[];

    for (final entry in entries) {
      switch (entry.quantity) {
        case MeasurableQuantity.temperature:
          temperature ??= entry;
        case MeasurableQuantity.humidity:
          humidity ??= entry;
        case MeasurableQuantity.pm25:
          pm25 ??= entry;
        case MeasurableQuantity.pm1:
          pm1 ??= entry;
        case MeasurableQuantity.pm10:
          pm10 ??= entry;
        case MeasurableQuantity.uva:
          uva ??= entry;
        case MeasurableQuantity.uvb:
          uvb ??= entry;
        case MeasurableQuantity.uvc:
          uvc ??= entry;
        case MeasurableQuantity.uvi:
          firmwareUvi ??= entry;
        case MeasurableQuantity.lux:
          lux ??= entry;
        case MeasurableQuantity.visible:
          visibleLight ??= entry;
        case MeasurableQuantity.infrared:
          infrared ??= entry;
        case MeasurableQuantity.fullSpectrum:
          fullSpectrum ??= entry;
        case MeasurableQuantity.rawLuminosity:
          break;
        case MeasurableQuantity.pm01:
        case MeasurableQuantity.pm4:
          gridOthers.add(entry);
        default:
          if (!_compositePmQuantities.contains(entry.quantity) &&
              !_uvBandQuantities.contains(entry.quantity) &&
              !_lightQuantities.contains(entry.quantity) &&
              entry.quantity != MeasurableQuantity.uvi &&
              entry.quantity != MeasurableQuantity.temperature &&
              entry.quantity != MeasurableQuantity.humidity) {
            gridOthers.add(entry);
          }
      }
    }

    return LatestMeasurementLayoutResult(
      temperature: temperature,
      humidity: humidity,
      pm25: pm25,
      pm1: pm1,
      pm10: pm10,
      uva: uva,
      uvb: uvb,
      uvc: uvc,
      firmwareUvi: firmwareUvi,
      lux: lux,
      visibleLight: visibleLight,
      infrared: infrared,
      fullSpectrum: fullSpectrum,
      gridOthers: gridOthers,
    );
  }

  static LatestMeasurementExpansionKey expansionKeyFor(MeasurementMetricEntry entry) {
    if (_compositePmQuantities.contains(entry.quantity) ||
        _otherPmQuantities.contains(entry.quantity)) {
      return LatestMeasurementExpansionKey.particulate;
    }
    return switch (entry.quantity) {
      MeasurableQuantity.uva ||
      MeasurableQuantity.uvb ||
      MeasurableQuantity.uvc ||
      MeasurableQuantity.uvi =>
        LatestMeasurementExpansionKey.uv,
      MeasurableQuantity.lux ||
      MeasurableQuantity.visible ||
      MeasurableQuantity.infrared ||
      MeasurableQuantity.fullSpectrum =>
        LatestMeasurementExpansionKey.light,
      MeasurableQuantity.voc => LatestMeasurementExpansionKey.voc,
      MeasurableQuantity.totalVoc => LatestMeasurementExpansionKey.totalVoc,
      MeasurableQuantity.nox => LatestMeasurementExpansionKey.nox,
      MeasurableQuantity.pressure => LatestMeasurementExpansionKey.pressure,
      MeasurableQuantity.co2 => LatestMeasurementExpansionKey.co2,
      MeasurableQuantity.o3 => LatestMeasurementExpansionKey.o3,
      MeasurableQuantity.aqi => LatestMeasurementExpansionKey.aqi,
      MeasurableQuantity.gasResistance => LatestMeasurementExpansionKey.gasResistance,
      _ => LatestMeasurementExpansionKey.voc,
    };
  }

  static ChartSeriesChartId? chartIdForExpansion(LatestMeasurementExpansionKey key) {
    return switch (key) {
      LatestMeasurementExpansionKey.particulate => ChartSeriesChartId.particulate,
      LatestMeasurementExpansionKey.climate ||
      LatestMeasurementExpansionKey.uv ||
      LatestMeasurementExpansionKey.light ||
      LatestMeasurementExpansionKey.environment ||
      LatestMeasurementExpansionKey.thermal =>
        null,
      LatestMeasurementExpansionKey.uva => ChartSeriesChartId.uva,
      LatestMeasurementExpansionKey.uvb => ChartSeriesChartId.uvb,
      LatestMeasurementExpansionKey.uvc => ChartSeriesChartId.uvc,
      LatestMeasurementExpansionKey.voc => ChartSeriesChartId.voc,
      LatestMeasurementExpansionKey.totalVoc => ChartSeriesChartId.totalVoc,
      LatestMeasurementExpansionKey.nox => ChartSeriesChartId.nox,
      LatestMeasurementExpansionKey.pressure => ChartSeriesChartId.pressure,
      LatestMeasurementExpansionKey.co2 => ChartSeriesChartId.co2,
      LatestMeasurementExpansionKey.o3 => ChartSeriesChartId.o3,
      LatestMeasurementExpansionKey.aqi => ChartSeriesChartId.aqi,
      LatestMeasurementExpansionKey.gasResistance => ChartSeriesChartId.gasResistance,
      LatestMeasurementExpansionKey.batteryPercentage ||
      LatestMeasurementExpansionKey.batteryVoltage =>
        null,
    };
  }

  static MeasurableQuantity? quantityForExpansion(LatestMeasurementExpansionKey key) {
    return switch (key) {
      LatestMeasurementExpansionKey.uva => MeasurableQuantity.uva,
      LatestMeasurementExpansionKey.uvb => MeasurableQuantity.uvb,
      LatestMeasurementExpansionKey.uvc => MeasurableQuantity.uvc,
      LatestMeasurementExpansionKey.voc => MeasurableQuantity.voc,
      LatestMeasurementExpansionKey.totalVoc => MeasurableQuantity.totalVoc,
      LatestMeasurementExpansionKey.nox => MeasurableQuantity.nox,
      LatestMeasurementExpansionKey.pressure => MeasurableQuantity.pressure,
      LatestMeasurementExpansionKey.co2 => MeasurableQuantity.co2,
      LatestMeasurementExpansionKey.o3 => MeasurableQuantity.o3,
      LatestMeasurementExpansionKey.aqi => MeasurableQuantity.aqi,
      LatestMeasurementExpansionKey.gasResistance => MeasurableQuantity.gasResistance,
      _ => null,
    };
  }

  static List<MeasurementTileId> availableTiles(
    LatestMeasurementLayoutResult layout, {
    required bool showBattery,
    required bool hasBattery,
  }) {
    final tiles = <MeasurementTileId>[];
    if (layout.hasParticulateComposite) {
      tiles.add(MeasurementTileId.particulate);
    }
    if (layout.hasClimatePair) {
      tiles.add(MeasurementTileId.climate);
    }
    if (layout.hasUvComposite) {
      tiles.add(MeasurementTileId.uv);
    }
    if (layout.hasLightComposite) {
      tiles.add(MeasurementTileId.light);
    }
    if (layout.hasEnvironmentContext) {
      tiles.add(MeasurementTileId.environment);
    }
    if (layout.hasThermalComfort) {
      tiles.add(MeasurementTileId.thermal);
    }
    if (layout.gridOthers.isNotEmpty || (showBattery && hasBattery)) {
      tiles.add(MeasurementTileId.others);
    }
    return tiles;
  }
}
