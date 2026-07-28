import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/uv_index.dart';
import 'package:luftdaten.at/features/measurements/logic/light_metrics.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/sensor_data_point_with_timestamp.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MeasurementSparklinePoint {
  const MeasurementSparklinePoint(this.timestamp, this.value);

  final DateTime timestamp;
  final double value;
}

class MeasurementSparklineData {
  MeasurementSparklineData._();

  static List<MeasurementSparklinePoint> forEntry({
    required MeasurementMetricEntry entry,
    required List<FlattenedDataPoint> flattenedData,
    required List<List<SensorDataPointWithTimestamp>> reshapedData,
  }) {
    if (_isFlattenedPmQuantity(entry.quantity)) {
      return flattenedData
          .map((point) {
            final value = _flattenedPmValue(point, entry.quantity);
            if (value == null) return null;
            return MeasurementSparklinePoint(point.timestamp, value);
          })
          .whereType<MeasurementSparklinePoint>()
          .toList();
    }

    for (final sensorSeries in reshapedData) {
      if (sensorSeries.isEmpty || sensorSeries.first.data.sensor != entry.sensor) {
        continue;
      }
      return sensorSeries
          .where((point) => point.data.values.containsKey(entry.quantity))
          .map(
            (point) => MeasurementSparklinePoint(
              point.timestamp,
              point.data.values[entry.quantity]!,
            ),
          )
          .toList();
    }
    return const [];
  }

  static bool _isFlattenedPmQuantity(MeasurableQuantity quantity) {
    return quantity == MeasurableQuantity.pm1 ||
        quantity == MeasurableQuantity.pm25 ||
        quantity == MeasurableQuantity.pm4 ||
        quantity == MeasurableQuantity.pm10;
  }

  static double? _flattenedPmValue(FlattenedDataPoint point, MeasurableQuantity quantity) {
    return switch (quantity) {
      MeasurableQuantity.pm1 => point.pm1,
      MeasurableQuantity.pm25 => point.pm25,
      MeasurableQuantity.pm4 => point.pm4,
      MeasurableQuantity.pm10 => point.pm10,
      _ => null,
    };
  }

  /// PM2.5-only sparkline for the particulate composite tile.
  static List<MeasurementSparklinePoint> forPm25({
    required List<FlattenedDataPoint> flattenedData,
  }) {
    return flattenedData
        .map((point) {
          final value = point.pm25;
          if (value == null) return null;
          return MeasurementSparklinePoint(point.timestamp, value);
        })
        .whereType<MeasurementSparklinePoint>()
        .toList();
  }

  /// UV Index sparkline for the UV composite tile.
  static List<MeasurementSparklinePoint> forUvIndex({
    required List<MeasuredDataPoint> history,
  }) {
    return UvIndex.sparklineFromHistory(history: history);
  }

  /// Lux sparkline for the light composite tile.
  static List<MeasurementSparklinePoint> forLux({
    required List<MeasuredDataPoint> history,
  }) {
    return LightMetrics.luxSparklineFromHistory(history: history);
  }
}

class MeasurementSparkline extends StatelessWidget {
  const MeasurementSparkline({
    super.key,
    required this.points,
    required this.color,
    this.width = 96,
    this.height = 40,
  });

  final List<MeasurementSparklinePoint> points;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(width: width, height: height);
    }

    return SizedBox(
      width: width,
      height: height,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        primaryXAxis: const DateTimeAxis(isVisible: false),
        primaryYAxis: const NumericAxis(isVisible: false),
        legend: const Legend(isVisible: false),
        tooltipBehavior: TooltipBehavior(enable: false),
        series: <CartesianSeries<MeasurementSparklinePoint, DateTime>>[
          LineSeries<MeasurementSparklinePoint, DateTime>(
            dataSource: points,
            xValueMapper: (point, _) => point.timestamp,
            yValueMapper: (point, _) => point.value,
            width: 2,
            color: color,
            markerSettings: const MarkerSettings(isVisible: false),
            dataLabelSettings: const DataLabelSettings(isVisible: false),
          ),
        ],
      ),
    );
  }
}

class MeasurementDualSparkline extends StatelessWidget {
  const MeasurementDualSparkline({
    super.key,
    required this.primaryPoints,
    required this.secondaryPoints,
    required this.primaryColor,
    required this.secondaryColor,
    this.width = 120,
    this.height = 40,
  });

  final List<MeasurementSparklinePoint> primaryPoints;
  final List<MeasurementSparklinePoint> secondaryPoints;
  final Color primaryColor;
  final Color secondaryColor;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (primaryPoints.length < 2 && secondaryPoints.length < 2) {
      return SizedBox(width: width, height: height);
    }

    return SizedBox(
      width: width,
      height: height,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        primaryXAxis: const DateTimeAxis(isVisible: false),
        primaryYAxis: const NumericAxis(isVisible: false),
        legend: const Legend(isVisible: false),
        tooltipBehavior: TooltipBehavior(enable: false),
        series: <CartesianSeries<MeasurementSparklinePoint, DateTime>>[
          if (primaryPoints.length >= 2)
            LineSeries<MeasurementSparklinePoint, DateTime>(
              dataSource: primaryPoints,
              xValueMapper: (point, _) => point.timestamp,
              yValueMapper: (point, _) => point.value,
              width: 2,
              color: primaryColor,
              markerSettings: const MarkerSettings(isVisible: false),
              dataLabelSettings: const DataLabelSettings(isVisible: false),
            ),
          if (secondaryPoints.length >= 2)
            LineSeries<MeasurementSparklinePoint, DateTime>(
              dataSource: secondaryPoints,
              xValueMapper: (point, _) => point.timestamp,
              yValueMapper: (point, _) => point.value,
              width: 2,
              color: secondaryColor,
              markerSettings: const MarkerSettings(isVisible: false),
              dataLabelSettings: const DataLabelSettings(isVisible: false),
            ),
        ],
      ),
    );
  }
}
