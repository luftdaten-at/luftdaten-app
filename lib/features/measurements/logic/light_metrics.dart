import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_sparkline.dart';

/// TSL2591 light metrics: lux hero, visible/infrared channels, derived IR share.
class LightMetrics {
  LightMetrics._();

  /// IR share in percent: infrared / fullSpectrum, or infrared / (visible + infrared).
  static double? irSharePercent({
    required double? infrared,
    required double? fullSpectrum,
    required double? visible,
  }) {
    if (infrared == null) return null;
    final denominator = fullSpectrum ?? ((visible ?? 0) + infrared);
    if (denominator <= 0) return null;
    return infrared / denominator * 100;
  }

  static String formatLux(double value) => value.toStringAsFixed(1);

  static String formatIrShare(double value) => '${value.toStringAsFixed(1)} %';

  static Color heroColor(double value) =>
      MeasurementMetricParser.statusColor(MeasurableQuantity.lux, value);

  static Color irShareColor(double value) =>
      MeasurementMetricParser.statusColor(MeasurableQuantity.infrared, value);

  /// Lux sparkline from trip history (first available lux per point).
  static List<MeasurementSparklinePoint> luxSparklineFromHistory({
    required List<MeasuredDataPoint> history,
  }) {
    final points = <MeasurementSparklinePoint>[];
    for (final point in history) {
      double? lux;
      for (final sensorData in point.sensorData) {
        if (sensorData.values.containsKey(MeasurableQuantity.lux)) {
          lux ??= sensorData.values[MeasurableQuantity.lux];
        }
      }
      if (lux != null) {
        points.add(MeasurementSparklinePoint(point.timestamp, lux));
      }
    }
    return points;
  }

  /// Resolve hero and side rows from visible metric entries (latest point).
  static LightSnapshot heroFromEntries({
    required MeasurementMetricEntry? lux,
    required MeasurementMetricEntry? visible,
    required MeasurementMetricEntry? infrared,
    required MeasurementMetricEntry? fullSpectrum,
  }) {
    final heroValue = lux?.value;
    final irShare = irSharePercent(
      infrared: infrared?.value,
      fullSpectrum: fullSpectrum?.value,
      visible: visible?.value,
    );
    return LightSnapshot(
      heroValue: heroValue,
      heroFormatted: heroValue != null ? formatLux(heroValue) : '-',
      heroColor: heroValue != null ? heroColor(heroValue) : Colors.grey.shade700,
      visible: visible,
      infrared: infrared,
      irSharePercent: irShare,
      irShareFormatted: irShare != null ? formatIrShare(irShare) : null,
      irShareColor: irShare != null ? irShareColor(irShare) : Colors.grey.shade700,
    );
  }
}

class LightSnapshot {
  const LightSnapshot({
    required this.heroValue,
    required this.heroFormatted,
    required this.heroColor,
    this.visible,
    this.infrared,
    this.irSharePercent,
    this.irShareFormatted,
    required this.irShareColor,
  });

  final double? heroValue;
  final String heroFormatted;
  final Color heroColor;
  final MeasurementMetricEntry? visible;
  final MeasurementMetricEntry? infrared;
  final double? irSharePercent;
  final String? irShareFormatted;
  final Color irShareColor;

  bool get hasAnyChannel =>
      visible != null || infrared != null || irSharePercent != null;
}
