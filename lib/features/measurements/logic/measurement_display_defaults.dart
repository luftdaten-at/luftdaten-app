import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';

/// Shared default visibility rules for chart series and value tiles.
abstract final class MeasurementDisplayDefaults {
  static bool hasSecondarySensorBesidesSen5x(Set<LDSensor> tripSensors) {
    return tripSensors.length > 1 &&
        tripSensors.contains(LDSensor.sen5x) &&
        tripSensors.any((s) => s != LDSensor.sen5x);
  }

  static MeasurableQuantity? quantityForChart(ChartSeriesChartId chartId) {
    return switch (chartId) {
      ChartSeriesChartId.temperature => MeasurableQuantity.temperature,
      ChartSeriesChartId.humidity => MeasurableQuantity.humidity,
      _ => null,
    };
  }

  static bool defaultSeriesVisible({
    required LDSensor sensor,
    MeasurableQuantity? quantity,
    ChartSeriesChartId? chartId,
    required Set<LDSensor> tripSensors,
  }) {
    final resolvedQuantity = quantity ?? (chartId != null ? quantityForChart(chartId) : null);
    if (resolvedQuantity == null) return true;
    if (!hasSecondarySensorBesidesSen5x(tripSensors)) return true;
    if (sensor != LDSensor.sen5x) return true;
    return resolvedQuantity != MeasurableQuantity.temperature &&
        resolvedQuantity != MeasurableQuantity.humidity;
  }

  static String seriesKey(LDSensor sensor, MeasurableQuantity quantity) =>
      '${sensor.name}:${quantity.toString().split('.').last}';
}
