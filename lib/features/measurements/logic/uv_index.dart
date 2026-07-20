import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/domain/dimensions.dart' as dim;
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_sparkline.dart';

/// Broadband approximation of the WHO/WMO UV Index from UVA/UVB irradiance.
///
/// Official UVI uses CIE erythemal spectral weighting × 40 m²/W. AS7331-style
/// band sensors only provide channel irradiances (µW/cm²), so we use the common
/// approximation: UVE = 0.17·UVA + 0.83·UVB (µW/cm²), then UVI = 40·UVE(W/m²).
/// UVC is excluded from the index. Prefer firmware [MeasurableQuantity.uvi] when present.
class UvIndex {
  UvIndex._();

  static const _uvaWeight = 0.17;
  static const _uvbWeight = 0.83;
  static const _wPerM2Factor = 0.4; // 40 m²/W × 0.01 (µW/cm² → W/m²)

  /// Returns UV Index from UVA/UVB in µW/cm², or null if both bands are missing.
  static double? computeFromIrradiance({required double? uva, required double? uvb}) {
    if (uva == null && uvb == null) return null;
    final uve = _uvaWeight * (uva ?? 0) + _uvbWeight * (uvb ?? 0);
    return uve * _wPerM2Factor;
  }

  /// Prefers firmware [uvi] when available; otherwise computes from UVA/UVB.
  static double? resolveHeroValue({
    required double? firmwareUvi,
    required double? uva,
    required double? uvb,
  }) {
    if (firmwareUvi != null) return firmwareUvi;
    return computeFromIrradiance(uva: uva, uvb: uvb);
  }

  static String formatValue(double value) => value.toStringAsFixed(1);

  static Color statusColor(double value) =>
      dim.Dimension.getColor(dim.Dimension.UVI, value) as Color? ?? Colors.grey.shade700;

  /// UV Index sparkline: firmware uvi per point when present, else computed from bands.
  static List<MeasurementSparklinePoint> sparklineFromHistory({
    required List<MeasuredDataPoint> history,
  }) {
    final points = <MeasurementSparklinePoint>[];
    for (final point in history) {
      double? firmwareUvi;
      double? uva;
      double? uvb;

      for (final sensorData in point.sensorData) {
        if (sensorData.values.containsKey(MeasurableQuantity.uvi)) {
          firmwareUvi = sensorData.values[MeasurableQuantity.uvi];
        }
        if (sensorData.values.containsKey(MeasurableQuantity.uva)) {
          uva ??= sensorData.values[MeasurableQuantity.uva];
        }
        if (sensorData.values.containsKey(MeasurableQuantity.uvb)) {
          uvb ??= sensorData.values[MeasurableQuantity.uvb];
        }
      }

      final value = resolveHeroValue(firmwareUvi: firmwareUvi, uva: uva, uvb: uvb);
      if (value != null) {
        points.add(MeasurementSparklinePoint(point.timestamp, value));
      }
    }
    return points;
  }

  /// Resolve hero from visible metric entries (latest point).
  static UvHeroSnapshot heroFromEntries({
    required MeasurementMetricEntry? uva,
    required MeasurementMetricEntry? uvb,
    required MeasurementMetricEntry? uvc,
    required MeasurementMetricEntry? firmwareUvi,
  }) {
    final heroValue = resolveHeroValue(
      firmwareUvi: firmwareUvi?.value,
      uva: uva?.value,
      uvb: uvb?.value,
    );
    return UvHeroSnapshot(
      heroValue: heroValue,
      heroFormatted: heroValue != null ? formatValue(heroValue) : '-',
      heroColor: heroValue != null ? statusColor(heroValue) : Colors.grey.shade700,
      uva: uva,
      uvb: uvb,
      uvc: uvc,
    );
  }
}

class UvHeroSnapshot {
  const UvHeroSnapshot({
    required this.heroValue,
    required this.heroFormatted,
    required this.heroColor,
    this.uva,
    this.uvb,
    this.uvc,
  });

  final double? heroValue;
  final String heroFormatted;
  final Color heroColor;
  final MeasurementMetricEntry? uva;
  final MeasurementMetricEntry? uvb;
  final MeasurementMetricEntry? uvc;

  bool get hasAnyBand => uva != null || uvb != null || uvc != null;
}
