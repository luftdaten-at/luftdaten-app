import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/logic/environment_context.dart';
import 'package:luftdaten.at/features/measurements/logic/light_metrics.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_bands.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_comfort_tracker.dart';
import 'package:luftdaten.at/features/measurements/logic/uv_index.dart';
import 'package:luftdaten.at/features/measurements/presentation/pages/chart_page.i18n.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/chart_section.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/latest_measurement_layout.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_sparkline.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/sensor_data_point_with_timestamp.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MeasurementChartBuilder {
  MeasurementChartBuilder._();

  static String chartHeadline(String title, String unit) =>
      '%s in %s'.i18n.fill([title.i18n, unit.i18n]);

  static NumericAxis measurementYAxis({String? name, bool opposed = false}) =>
      NumericAxis(name: name, opposedPosition: opposed);

  static Color _seriesColor(MeasurableQuantity quantity, double? latestValue) {
    if (latestValue == null) return Colors.grey.shade700;
    return MeasurementMetricParser.statusColor(quantity, latestValue);
  }

  static double? _latestNonNull(Iterable<double?> values) {
    for (final value in values.toList().reversed) {
      if (value != null) return value;
    }
    return null;
  }

  static Widget? buildParticulateChart({
    required List<FlattenedDataPoint> data,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    if (data.isEmpty) return null;

    final options = <ChartSeriesOption>[
      if (data.first.pm1 != null)
        const ChartSeriesOption(key: ChartSeriesKeys.pm1, label: 'PM1.0'),
      if (data.first.pm25 != null)
        const ChartSeriesOption(key: ChartSeriesKeys.pm25, label: 'PM2.5'),
      if (data.first.pm4 != null)
        const ChartSeriesOption(key: ChartSeriesKeys.pm4, label: 'PM4.0'),
      if (data.first.pm10 != null)
        const ChartSeriesOption(key: ChartSeriesKeys.pm10, label: 'PM10.0'),
    ];
    if (options.isEmpty) return null;

    final latestPm1 = _latestNonNull(data.map((e) => e.pm1));
    final latestPm25 = _latestNonNull(data.map((e) => e.pm25));
    final latestPm4 = _latestNonNull(data.map((e) => e.pm4));
    final latestPm10 = _latestNonNull(data.map((e) => e.pm10));

    final series = <CartesianSeries<FlattenedDataPoint, DateTime>>[];
    if (data.first.pm1 != null &&
        preferences.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm1)) {
      series.add(LineSeries<FlattenedDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.pm1,
        name: 'PM1.0',
        color: _seriesColor(MeasurableQuantity.pm1, latestPm1),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (data.first.pm25 != null &&
        preferences.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm25)) {
      series.add(LineSeries<FlattenedDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.pm25,
        name: 'PM2.5',
        color: _seriesColor(MeasurableQuantity.pm25, latestPm25),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (data.first.pm4 != null &&
        preferences.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm4)) {
      series.add(LineSeries<FlattenedDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.pm4,
        name: 'PM4.0',
        color: _seriesColor(MeasurableQuantity.pm4, latestPm4),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (data.first.pm10 != null &&
        preferences.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm10)) {
      series.add(LineSeries<FlattenedDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.pm10,
        name: 'PM10.0',
        color: _seriesColor(MeasurableQuantity.pm10, latestPm10),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (series.isEmpty) return null;

    return ChartSection(
      title: chartHeadline('Feinstaubbelastung', 'μg/m³'),
      chartId: ChartSeriesChartId.particulate,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: _measurementChart(series: series),
    );
  }

  static Widget? buildUvBandsChart({
    required List<MeasuredDataPoint> history,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final data = _uvBandPointsFromHistory(history);
    if (data.isEmpty) return null;

    final hasUva = data.any((p) => p.uva != null);
    final hasUvb = data.any((p) => p.uvb != null);
    final hasUvc = data.any((p) => p.uvc != null);

    final options = <ChartSeriesOption>[
      if (hasUva) const ChartSeriesOption(key: ChartSeriesKeys.uva, label: 'UVA'),
      if (hasUvb) const ChartSeriesOption(key: ChartSeriesKeys.uvb, label: 'UVB'),
      if (hasUvc) const ChartSeriesOption(key: ChartSeriesKeys.uvc, label: 'UVC'),
    ];
    if (options.isEmpty) return null;

    final latestUva = _latestNonNull(data.map((e) => e.uva));
    final latestUvb = _latestNonNull(data.map((e) => e.uvb));
    final latestUvc = _latestNonNull(data.map((e) => e.uvc));

    final series = <CartesianSeries<_UvBandDataPoint, DateTime>>[];
    if (hasUva &&
        preferences.isVisible(ChartSeriesChartId.uvBands, ChartSeriesKeys.uva)) {
      series.add(LineSeries<_UvBandDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.uva,
        name: 'UVA',
        color: _seriesColor(MeasurableQuantity.uva, latestUva),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (hasUvb &&
        preferences.isVisible(ChartSeriesChartId.uvBands, ChartSeriesKeys.uvb)) {
      series.add(LineSeries<_UvBandDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.uvb,
        name: 'UVB',
        color: _seriesColor(MeasurableQuantity.uvb, latestUvb),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (hasUvc &&
        preferences.isVisible(ChartSeriesChartId.uvBands, ChartSeriesKeys.uvc)) {
      series.add(LineSeries<_UvBandDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.uvc,
        name: 'UVC',
        color: _seriesColor(MeasurableQuantity.uvc, latestUvc),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (series.isEmpty) return null;

    return ChartSection(
      title: chartHeadline('UV-Bestrahlung', 'µW/cm²'),
      chartId: ChartSeriesChartId.uvBands,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: _measurementChart(series: series),
    );
  }

  static Widget? buildUvIndexChart({
    required List<MeasuredDataPoint> history,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final points = UvIndex.sparklineFromHistory(history: history);
    if (points.isEmpty) return null;
    if (!preferences.isVisible(ChartSeriesChartId.uvIndex, ChartSeriesKeys.uvi)) {
      return null;
    }

    final latestUvi = points.last.value;

    return ChartSection(
      title: 'UV-Index'.i18n,
      chartId: ChartSeriesChartId.uvIndex,
      seriesOptions: const [
        ChartSeriesOption(key: ChartSeriesKeys.uvi, label: 'UV-Index'),
      ],
      tripSensors: tripSensors,
      chart: _measurementChart(
        series: [
          LineSeries<MeasurementSparklinePoint, DateTime>(
            dataSource: points,
            xValueMapper: (item, _) => item.timestamp,
            yValueMapper: (item, _) => item.value,
            name: 'UV-Index'.i18n,
            color: _seriesColor(MeasurableQuantity.uvi, latestUvi),
            dataLabelSettings: const DataLabelSettings(isVisible: false),
          ),
        ],
      ),
    );
  }

  static Widget? buildIlluminanceChart({
    required List<MeasuredDataPoint> history,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final points = LightMetrics.luxSparklineFromHistory(history: history);
    if (points.isEmpty) return null;
    if (!preferences.isVisible(ChartSeriesChartId.illuminance, ChartSeriesKeys.lux)) {
      return null;
    }

    final latestLux = points.last.value;

    return ChartSection(
      title: chartHeadline('Beleuchtungsstärke', 'lx'),
      chartId: ChartSeriesChartId.illuminance,
      seriesOptions: const [
        ChartSeriesOption(key: ChartSeriesKeys.lux, label: 'Lux'),
      ],
      tripSensors: tripSensors,
      chart: _measurementChart(
        series: [
          LineSeries<MeasurementSparklinePoint, DateTime>(
            dataSource: points,
            xValueMapper: (item, _) => item.timestamp,
            yValueMapper: (item, _) => item.value,
            name: 'Beleuchtungsstärke'.i18n,
            color: _seriesColor(MeasurableQuantity.lux, latestLux),
            dataLabelSettings: const DataLabelSettings(isVisible: false),
          ),
        ],
      ),
    );
  }

  static Widget? buildLightChannelsChart({
    required List<MeasuredDataPoint> history,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final data = _lightPointsFromHistory(history);
    if (data.isEmpty) return null;

    final hasVisible = data.any((p) => p.visible != null);
    final hasInfrared = data.any((p) => p.infrared != null);
    final hasFullSpectrum = data.any((p) => p.fullSpectrum != null);

    final options = <ChartSeriesOption>[
      if (hasVisible)
        const ChartSeriesOption(key: ChartSeriesKeys.visibleLight, label: 'Visible light'),
      if (hasInfrared)
        const ChartSeriesOption(key: ChartSeriesKeys.infrared, label: 'Infrared'),
      if (hasFullSpectrum)
        const ChartSeriesOption(key: ChartSeriesKeys.fullSpectrum, label: 'Full spectrum'),
    ];
    if (options.isEmpty) return null;

    final latestVisible = _latestNonNull(data.map((e) => e.visible));
    final latestInfrared = _latestNonNull(data.map((e) => e.infrared));
    final latestFullSpectrum = _latestNonNull(data.map((e) => e.fullSpectrum));

    final series = <CartesianSeries<_LightDataPoint, DateTime>>[];
    if (hasVisible &&
        preferences.isVisible(ChartSeriesChartId.lightChannels, ChartSeriesKeys.visibleLight)) {
      series.add(LineSeries<_LightDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.visible,
        name: 'Sichtbares Licht'.i18n,
        color: _seriesColor(MeasurableQuantity.visible, latestVisible),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (hasInfrared &&
        preferences.isVisible(ChartSeriesChartId.lightChannels, ChartSeriesKeys.infrared)) {
      series.add(LineSeries<_LightDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.infrared,
        name: 'Infrarot'.i18n,
        color: _seriesColor(MeasurableQuantity.infrared, latestInfrared),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (hasFullSpectrum &&
        preferences.isVisible(ChartSeriesChartId.lightChannels, ChartSeriesKeys.fullSpectrum)) {
      series.add(LineSeries<_LightDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.fullSpectrum,
        name: 'Vollspektrum'.i18n,
        color: _seriesColor(MeasurableQuantity.fullSpectrum, latestFullSpectrum),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (series.isEmpty) return null;

    return ChartSection(
      title: 'Lichtkanäle'.i18n,
      chartId: ChartSeriesChartId.lightChannels,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: _measurementChart(series: series),
    );
  }

  static List<_LightDataPoint> _lightPointsFromHistory(List<MeasuredDataPoint> history) {
    final points = <_LightDataPoint>[];
    for (final point in history) {
      double? lux;
      double? visible;
      double? infrared;
      double? fullSpectrum;

      for (final sensorData in point.sensorData) {
        if (sensorData.values.containsKey(MeasurableQuantity.lux)) {
          lux ??= sensorData.values[MeasurableQuantity.lux];
        }
        if (sensorData.values.containsKey(MeasurableQuantity.visible)) {
          visible ??= sensorData.values[MeasurableQuantity.visible];
        }
        if (sensorData.values.containsKey(MeasurableQuantity.infrared)) {
          infrared ??= sensorData.values[MeasurableQuantity.infrared];
        }
        if (sensorData.values.containsKey(MeasurableQuantity.fullSpectrum)) {
          fullSpectrum ??= sensorData.values[MeasurableQuantity.fullSpectrum];
        }
      }

      if (visible != null || infrared != null || fullSpectrum != null || lux != null) {
        points.add(_LightDataPoint(
          timestamp: point.timestamp,
          lux: lux,
          visible: visible,
          infrared: infrared,
          fullSpectrum: fullSpectrum,
        ));
      }
    }
    return points;
  }

  static List<_UvBandDataPoint> _uvBandPointsFromHistory(List<MeasuredDataPoint> history) {
    final points = <_UvBandDataPoint>[];
    for (final point in history) {
      double? uva;
      double? uvb;
      double? uvc;

      for (final sensorData in point.sensorData) {
        if (sensorData.values.containsKey(MeasurableQuantity.uva)) {
          uva ??= sensorData.values[MeasurableQuantity.uva];
        }
        if (sensorData.values.containsKey(MeasurableQuantity.uvb)) {
          uvb ??= sensorData.values[MeasurableQuantity.uvb];
        }
        if (sensorData.values.containsKey(MeasurableQuantity.uvc)) {
          uvc ??= sensorData.values[MeasurableQuantity.uvc];
        }
      }

      if (uva != null || uvb != null || uvc != null) {
        points.add(_UvBandDataPoint(
          timestamp: point.timestamp,
          uva: uva,
          uvb: uvb,
          uvc: uvc,
        ));
      }
    }
    return points;
  }

  static Widget? buildMetricChart({
    required ChartSeriesChartId chartId,
    required String title,
    required String yAxisTitle,
    required List<List<SensorDataPointWithTimestamp>> data,
    required MeasurableQuantity dimension,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final qualifyingData = data
        .where((e) => e.firstOrNull?.data.values.containsKey(dimension) ?? false)
        .toList();
    if (qualifyingData.isEmpty) return null;

    final latestValue = _latestNonNull(
      qualifyingData.expand(
        (sensorData) => sensorData.map((point) => point.data.values[dimension]),
      ),
    );
    final seriesColor = _seriesColor(dimension, latestValue);

    final options = <ChartSeriesOption>[
      for (final sensorData in qualifyingData)
        ChartSeriesOption(
          key: sensorData.first.data.sensor.name,
          label: sensorData.first.data.sensor.shortName,
        ),
      if (qualifyingData.length > 1)
        ChartSeriesOption(key: ChartSeriesKeys.mean, label: 'Mittelwert'.i18n),
    ];

    final series = <LineSeries<SensorDataPointWithTimestamp, DateTime>>[];
    for (final sensorData in qualifyingData) {
      final sensorKey = sensorData.first.data.sensor.name;
      if (!preferences.isVisible(chartId, sensorKey, tripSensors: tripSensors)) continue;
      series.add(LineSeries<SensorDataPointWithTimestamp, DateTime>(
        dataSource: sensorData,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.data.values[dimension]!,
        name: sensorData.first.data.sensor.shortName,
        color: seriesColor,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (qualifyingData.length > 1 &&
        preferences.isVisible(chartId, ChartSeriesKeys.mean, tripSensors: tripSensors)) {
      final meanData = <SensorDataPointWithTimestamp>[];
      for (var i = 0; i < qualifyingData.first.length; i++) {
        var sum = 0.0;
        for (final sensorData in qualifyingData) {
          sum += sensorData[i].data.values[dimension]!;
        }
        meanData.add(SensorDataPointWithTimestamp(
          qualifyingData.first[i].timestamp,
          SensorDataPoint(
            sensor: LDSensor.all,
            values: {dimension: sum / qualifyingData.length},
          ),
        ));
      }
      series.add(LineSeries<SensorDataPointWithTimestamp, DateTime>(
        dataSource: meanData,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.data.values[dimension]!,
        name: 'Mittelwert'.i18n,
        width: 4,
        color: seriesColor,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (series.isEmpty) return null;

    return ChartSection(
      title: chartHeadline(title, yAxisTitle),
      chartId: chartId,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: _measurementChart(series: series),
    );
  }

  static Widget? buildClimateChart({
    required List<List<SensorDataPointWithTimestamp>> data,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final tempSeries = _buildDimensionSeries(
      data: data,
      dimension: MeasurableQuantity.temperature,
      chartId: ChartSeriesChartId.temperature,
      preferences: preferences,
      tripSensors: tripSensors,
      yAxisName: 'temperature',
    );
    final humSeries = _buildDimensionSeries(
      data: data,
      dimension: MeasurableQuantity.humidity,
      chartId: ChartSeriesChartId.humidity,
      preferences: preferences,
      tripSensors: tripSensors,
      yAxisName: 'humidity',
    );
    if (tempSeries.isEmpty && humSeries.isEmpty) return null;

    final options = <ChartSeriesOption>[
      ...tempSeries.map(
        (s) => ChartSeriesOption(key: s.name ?? 'temp', label: s.name ?? 'Temperatur'),
      ),
      ...humSeries.map(
        (s) => ChartSeriesOption(key: s.name ?? 'hum', label: s.name ?? 'Luftfeuchtigkeit'),
      ),
    ];

    return ChartSection(
      title: 'Temperatur und relative Luftfeuchtigkeit'.i18n,
      chartId: ChartSeriesChartId.temperature,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: SfCartesianChart(
        primaryXAxis: DateTimeAxis(dateFormat: DateFormat('MMM d\nHH:mm')),
        primaryYAxis: measurementYAxis(name: 'temperature'),
        axes: <ChartAxis>[
          measurementYAxis(name: 'humidity', opposed: true),
        ],
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          enablePinching: true,
          enableDoubleTapZooming: true,
          zoomMode: ZoomMode.x,
          enableSelectionZooming: true,
        ),
        legend: Legend(
          isVisible: tempSeries.length + humSeries.length > 1,
          position: LegendPosition.bottom,
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<dynamic, DateTime>>[
          ...tempSeries,
          ...humSeries,
        ],
      ),
    );
  }

  static List<LineSeries<SensorDataPointWithTimestamp, DateTime>> _buildDimensionSeries({
    required List<List<SensorDataPointWithTimestamp>> data,
    required MeasurableQuantity dimension,
    required ChartSeriesChartId chartId,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
    required String yAxisName,
  }) {
    final qualifyingData = data
        .where((e) => e.firstOrNull?.data.values.containsKey(dimension) ?? false)
        .toList();
    if (qualifyingData.isEmpty) return [];

    final latestValue = _latestNonNull(
      qualifyingData.expand(
        (sensorData) => sensorData.map((point) => point.data.values[dimension]),
      ),
    );
    final seriesColor = _seriesColor(dimension, latestValue);

    final series = <LineSeries<SensorDataPointWithTimestamp, DateTime>>[];
    for (final sensorData in qualifyingData) {
      final sensorKey = sensorData.first.data.sensor.name;
      if (!preferences.isVisible(chartId, sensorKey, tripSensors: tripSensors)) continue;
      series.add(LineSeries<SensorDataPointWithTimestamp, DateTime>(
        dataSource: sensorData,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.data.values[dimension]!,
        name: dimension == MeasurableQuantity.temperature
            ? '${sensorData.first.data.sensor.shortName} (°C)'
            : '${sensorData.first.data.sensor.shortName} (%)',
        yAxisName: yAxisName,
        color: seriesColor,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    return series;
  }

  static Widget? buildBatteryChart({required bool voltage}) {
    final batteryData = getIt<BatteryInfoAggregator>().collectedBatteryDetails;
    if (batteryData.isEmpty) return null;

    final headline = voltage
        ? chartHeadline('Batteriestatus', '%')
        : chartHeadline('Batteriespannung', 'V');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CenteredChartHeadline(title: headline),
        SfCartesianChart(
          primaryXAxis: DateTimeAxis(dateFormat: DateFormat('MMM d\nHH:mm')),
          primaryYAxis: measurementYAxis(),
          zoomPanBehavior: ZoomPanBehavior(
            enablePanning: true,
            enablePinching: true,
            enableDoubleTapZooming: true,
            zoomMode: ZoomMode.x,
            enableSelectionZooming: true,
          ),
          legend: const Legend(isVisible: false, position: LegendPosition.bottom),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: [
            LineSeries<BatteryDetails, DateTime>(
              dataSource: batteryData,
              xValueMapper: (item, _) => item.timestamp,
              yValueMapper: (item, _) => voltage ? item.percentage : item.voltage,
              name: 'Batteriestatus'.i18n,
              dataLabelSettings: const DataLabelSettings(isVisible: false),
            ),
          ],
        ),
      ],
    );
  }

  static Widget? buildEnvironmentScoreChart({
    required EnvironmentContextAnalysis analysis,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    if (analysis.isEmpty) return null;
    if (!preferences.isVisible(
      ChartSeriesChartId.environmentScore,
      ChartSeriesKeys.environmentScore,
    )) {
      return null;
    }

    final samples = analysis.samples;
    final stateColor =
        EnvironmentContextClassifier.stateColor(samples.last.state);

    return ChartSection(
      title: 'Innen/Außen-Score'.i18n,
      chartId: ChartSeriesChartId.environmentScore,
      seriesOptions: const [
        ChartSeriesOption(
          key: ChartSeriesKeys.environmentScore,
          label: 'Indoor/outdoor score',
        ),
      ],
      tripSensors: tripSensors,
      chart: _measurementChart(
        yAxis: NumericAxis(
          minimum: -1,
          maximum: 1,
          interval: 0.5,
          plotBands: <PlotBand>[
            // Inside this band no switch happens; the previous state is held.
            PlotBand(
              start: -EnvironmentContextClassifier.switchThreshold,
              end: EnvironmentContextClassifier.switchThreshold,
              color: Colors.grey.withValues(alpha: 0.15),
            ),
          ],
        ),
        series: [
          LineSeries<EnvironmentContextSample, DateTime>(
            dataSource: samples,
            xValueMapper: (item, _) => item.timestamp,
            yValueMapper: (item, _) => item.score,
            name: 'Innen/Außen-Score'.i18n,
            color: stateColor,
            dataLabelSettings: const DataLabelSettings(isVisible: false),
          ),
        ],
      ),
    );
  }

  /// The raw ratios behind the classification, so thresholds stay reviewable
  /// against real trips instead of being a black box.
  static Widget? buildEnvironmentFeatureChart({
    required EnvironmentContextAnalysis analysis,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    if (analysis.isEmpty) return null;

    final samples = analysis.samples;
    final hasKUv = samples.any((e) => e.features.kUv != null);
    final hasBeta = samples.any((e) => e.features.beta != null);

    final options = <ChartSeriesOption>[
      if (hasKUv) const ChartSeriesOption(key: ChartSeriesKeys.kUv, label: 'k_UV'),
      if (hasBeta) const ChartSeriesOption(key: ChartSeriesKeys.betaUv, label: 'UVB/UVA'),
    ];
    if (options.isEmpty) return null;

    final latestUva = _latestNonNull(samples.map((e) => e.features.uva));
    final latestUvb = _latestNonNull(samples.map((e) => e.features.uvb));

    final series = <CartesianSeries<EnvironmentContextSample, DateTime>>[];
    if (hasKUv &&
        preferences.isVisible(
          ChartSeriesChartId.environmentFeatures,
          ChartSeriesKeys.kUv,
        )) {
      series.add(LineSeries<EnvironmentContextSample, DateTime>(
        dataSource: samples,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.features.kUv,
        name: 'UV-Anteil (k_UV)'.i18n,
        color: _seriesColor(MeasurableQuantity.uva, latestUva),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (hasBeta &&
        preferences.isVisible(
          ChartSeriesChartId.environmentFeatures,
          ChartSeriesKeys.betaUv,
        )) {
      series.add(LineSeries<EnvironmentContextSample, DateTime>(
        dataSource: samples,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.features.beta,
        name: 'Glasindikator (UVB/UVA)'.i18n,
        color: _seriesColor(MeasurableQuantity.uvb, latestUvb),
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (series.isEmpty) return null;

    return ChartSection(
      title: 'Klassifikationsmerkmale'.i18n,
      chartId: ChartSeriesChartId.environmentFeatures,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: _measurementChart(series: series),
    );
  }

  static Widget? buildUtciChart({
    required ThermalComfortAnalysis analysis,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final utciSamples =
        analysis.samples.where((s) => s.reading.utciC != null).toList();
    if (utciSamples.isEmpty) return null;

    final options = <ChartSeriesOption>[
      const ChartSeriesOption(key: ChartSeriesKeys.utci, label: 'UTCI'),
      const ChartSeriesOption(key: ChartSeriesKeys.tAir, label: 'Air temperature'),
      const ChartSeriesOption(key: ChartSeriesKeys.tMrt, label: 'Mean radiant temperature'),
    ];

    final series = <CartesianSeries<ThermalComfortSample, DateTime>>[];
    if (preferences.isVisible(ChartSeriesChartId.utci, ChartSeriesKeys.utci)) {
      final latest = utciSamples.last.reading.utciC!;
      series.add(LineSeries<ThermalComfortSample, DateTime>(
        dataSource: utciSamples,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.reading.utciC,
        name: 'UTCI'.i18n,
        color: UtciStressBand.fromUtci(latest).color,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (preferences.isVisible(ChartSeriesChartId.utci, ChartSeriesKeys.tAir)) {
      series.add(LineSeries<ThermalComfortSample, DateTime>(
        dataSource: utciSamples,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.reading.tAirC,
        name: 'Temperatur'.i18n,
        color: Colors.blueGrey,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (preferences.isVisible(ChartSeriesChartId.utci, ChartSeriesKeys.tMrt)) {
      series.add(LineSeries<ThermalComfortSample, DateTime>(
        dataSource: utciSamples,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.reading.tMrtC,
        name: 'T_mrt'.i18n,
        color: Colors.deepOrange,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (series.isEmpty) return null;

    return ChartSection(
      title: 'UTCI'.i18n,
      chartId: ChartSeriesChartId.utci,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: _measurementChart(
        yAxis: NumericAxis(
          plotBands: <PlotBand>[
            PlotBand(start: 26, end: 32, color: Colors.amber.withValues(alpha: 0.08)),
            PlotBand(start: 32, end: 46, color: Colors.orange.withValues(alpha: 0.08)),
          ],
        ),
        series: series,
      ),
    );
  }

  static Widget? buildThermalDriverChart({
    required ThermalComfortAnalysis analysis,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final samples = analysis.samples
        .where((s) => s.reading.fSun != null || s.reading.v10Ms != null)
        .toList();
    if (samples.isEmpty) return null;

    final options = <ChartSeriesOption>[
      const ChartSeriesOption(key: ChartSeriesKeys.fSun, label: 'Sun exposure'),
      const ChartSeriesOption(key: ChartSeriesKeys.v10, label: 'Wind speed'),
    ];

    final series = <CartesianSeries<ThermalComfortSample, DateTime>>[];
    if (preferences.isVisible(ChartSeriesChartId.thermalDrivers, ChartSeriesKeys.fSun)) {
      series.add(LineSeries<ThermalComfortSample, DateTime>(
        dataSource: samples,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.fSun,
        name: 'Sonnenanteil'.i18n,
        color: Colors.amber.shade800,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (preferences.isVisible(ChartSeriesChartId.thermalDrivers, ChartSeriesKeys.v10)) {
      series.add(LineSeries<ThermalComfortSample, DateTime>(
        dataSource: samples,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.reading.v10Ms,
        name: 'Wind'.i18n,
        yAxisName: 'wind',
        color: Colors.teal,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (series.isEmpty) return null;

    return ChartSection(
      title: 'Thermische Treiber'.i18n,
      chartId: ChartSeriesChartId.thermalDrivers,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: _measurementChart(
        yAxis: NumericAxis(minimum: 0, maximum: 1, name: 'f_sun'),
        series: series,
        secondaryYAxis: NumericAxis(
          name: 'wind',
          opposedPosition: true,
          minimum: 0,
        ),
      ),
    );
  }

  static Widget buildExpandedChart({
    required LatestMeasurementExpansionKey expansionKey,
    required List<MeasuredDataPoint> history,
    required List<FlattenedDataPoint> flattenedData,
    required List<List<SensorDataPointWithTimestamp>> reshapedData,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    return switch (expansionKey) {
      LatestMeasurementExpansionKey.particulate =>
        buildParticulateChart(
              data: flattenedData,
              preferences: preferences,
              tripSensors: tripSensors,
            ) ??
            const SizedBox.shrink(),
      LatestMeasurementExpansionKey.climate =>
        buildClimateChart(
              data: reshapedData,
              preferences: preferences,
              tripSensors: tripSensors,
            ) ??
            const SizedBox.shrink(),
      LatestMeasurementExpansionKey.uv => _buildUvExpansionCharts(
          history: history,
          preferences: preferences,
          tripSensors: tripSensors,
        ),
      LatestMeasurementExpansionKey.light => _buildLightExpansionCharts(
          history: history,
          preferences: preferences,
          tripSensors: tripSensors,
        ),
      LatestMeasurementExpansionKey.environment => _buildEnvironmentExpansionCharts(
          history: history,
          preferences: preferences,
          tripSensors: tripSensors,
        ),
      LatestMeasurementExpansionKey.thermal => _buildThermalExpansionCharts(
          history: history,
          preferences: preferences,
          tripSensors: tripSensors,
        ),
      LatestMeasurementExpansionKey.batteryPercentage =>
        buildBatteryChart(voltage: true) ?? const SizedBox.shrink(),
      LatestMeasurementExpansionKey.batteryVoltage =>
        buildBatteryChart(voltage: false) ?? const SizedBox.shrink(),
      _ => _buildGridExpansionChart(
          key: expansionKey,
          reshapedData: reshapedData,
          preferences: preferences,
          tripSensors: tripSensors,
        ),
    };
  }

  static Widget _buildUvExpansionCharts({
    required List<MeasuredDataPoint> history,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final charts = <Widget>[];

    final bandsChart = buildUvBandsChart(
      history: history,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (bandsChart != null) charts.add(bandsChart);

    final indexChart = buildUvIndexChart(
      history: history,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (indexChart != null) charts.add(indexChart);

    if (charts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: charts,
    );
  }

  static Widget _buildLightExpansionCharts({
    required List<MeasuredDataPoint> history,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final charts = <Widget>[];

    final illuminanceChart = buildIlluminanceChart(
      history: history,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (illuminanceChart != null) charts.add(illuminanceChart);

    final channelsChart = buildLightChannelsChart(
      history: history,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (channelsChart != null) charts.add(channelsChart);

    if (charts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: charts,
    );
  }

  static Widget _buildEnvironmentExpansionCharts({
    required List<MeasuredDataPoint> history,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final analysis = EnvironmentContextClassifier.analyze(history: history);
    final charts = <Widget>[];

    final scoreChart = buildEnvironmentScoreChart(
      analysis: analysis,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (scoreChart != null) charts.add(scoreChart);

    final featureChart = buildEnvironmentFeatureChart(
      analysis: analysis,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (featureChart != null) charts.add(featureChart);

    if (charts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: charts,
    );
  }

  static Widget _buildThermalExpansionCharts({
    required List<MeasuredDataPoint> history,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final analysis = ThermalComfortAnalysis.analyze(history: history);
    final charts = <Widget>[];

    final utciChart = buildUtciChart(
      analysis: analysis,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (utciChart != null) charts.add(utciChart);

    final driverChart = buildThermalDriverChart(
      analysis: analysis,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (driverChart != null) charts.add(driverChart);

    if (charts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: charts,
    );
  }

  static Widget _buildGridExpansionChart({
    required LatestMeasurementExpansionKey key,
    required List<List<SensorDataPointWithTimestamp>> reshapedData,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final chartId = LatestMeasurementLayout.chartIdForExpansion(key);
    final quantity = LatestMeasurementLayout.quantityForExpansion(key);
    if (chartId == null || quantity == null) return const SizedBox.shrink();

    final config = _chartConfigFor(key);
    return buildMetricChart(
          chartId: chartId,
          title: config.$1,
          yAxisTitle: config.$2,
          data: reshapedData,
          dimension: quantity,
          preferences: preferences,
          tripSensors: tripSensors,
        ) ??
        const SizedBox.shrink();
  }

  static (String, String) _chartConfigFor(LatestMeasurementExpansionKey key) {
    return switch (key) {
      LatestMeasurementExpansionKey.uva => ('UVA', 'µW/cm²'),
      LatestMeasurementExpansionKey.uvb => ('UVB', 'µW/cm²'),
      LatestMeasurementExpansionKey.uvc => ('UVC', 'µW/cm²'),
      LatestMeasurementExpansionKey.voc => ('Flüchtige organische Verbindungen (VOC)', 'Index (%)'),
      LatestMeasurementExpansionKey.totalVoc =>
        ('Flüchtige organische Verbindungen (VOC)', 'ppm'),
      LatestMeasurementExpansionKey.nox => ('Stickoxide (NOx)', 'Index (%)'),
      LatestMeasurementExpansionKey.pressure => ('Luftdruck', 'hPa'),
      LatestMeasurementExpansionKey.co2 => ('CO₂', 'ppm'),
      LatestMeasurementExpansionKey.o3 => ('O₃', 'ppb'),
      LatestMeasurementExpansionKey.aqi => ('Air Quality Index', 'Index'),
      LatestMeasurementExpansionKey.gasResistance => ('Gaswiderstand', 'Index'),
      _ => ('', ''),
    };
  }

  static SfCartesianChart _measurementChart({
    required List<CartesianSeries<dynamic, DateTime>> series,
    NumericAxis? yAxis,
    NumericAxis? secondaryYAxis,
  }) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(dateFormat: DateFormat('MMM d\nHH:mm')),
      primaryYAxis: yAxis ?? measurementYAxis(),
      axes: secondaryYAxis != null ? <ChartAxis>[secondaryYAxis] : const [],
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
        enableDoubleTapZooming: true,
        zoomMode: ZoomMode.x,
        enableSelectionZooming: true,
      ),
      legend: Legend(
        isVisible: series.length > 1,
        position: LegendPosition.bottom,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: series,
    );
  }
}

class _UvBandDataPoint {
  const _UvBandDataPoint({
    required this.timestamp,
    this.uva,
    this.uvb,
    this.uvc,
  });

  final DateTime timestamp;
  final double? uva;
  final double? uvb;
  final double? uvc;
}

class _LightDataPoint {
  const _LightDataPoint({
    required this.timestamp,
    this.lux,
    this.visible,
    this.infrared,
    this.fullSpectrum,
  });

  final DateTime timestamp;
  final double? lux;
  final double? visible;
  final double? infrared;
  final double? fullSpectrum;
}
