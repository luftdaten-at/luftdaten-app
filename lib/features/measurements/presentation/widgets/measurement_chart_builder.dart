import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/presentation/pages/chart_page.i18n.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/chart_section.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/latest_measurement_layout.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/sensor_data_point_with_timestamp.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MeasurementChartBuilder {
  MeasurementChartBuilder._();

  static String chartHeadline(String title, String unit) =>
      '%s in %s'.i18n.fill([title.i18n, unit.i18n]);

  static NumericAxis measurementYAxis({String? name, bool opposed = false}) =>
      NumericAxis(name: name, opposedPosition: opposed);

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

    final series = <CartesianSeries<FlattenedDataPoint, DateTime>>[];
    if (data.first.pm1 != null &&
        preferences.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm1)) {
      series.add(LineSeries<FlattenedDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (item, _) => item.timestamp,
        yValueMapper: (item, _) => item.pm1,
        name: 'PM1.0',
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

  static Widget buildExpandedChart({
    required LatestMeasurementExpansionKey expansionKey,
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
          reshapedData: reshapedData,
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
    required List<List<SensorDataPointWithTimestamp>> reshapedData,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    final charts = <Widget>[];
    final uvaChart = buildMetricChart(
      chartId: ChartSeriesChartId.uva,
      title: 'UVA',
      yAxisTitle: 'µW/cm²',
      data: reshapedData,
      dimension: MeasurableQuantity.uva,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (uvaChart != null) charts.add(uvaChart);

    final uvbChart = buildMetricChart(
      chartId: ChartSeriesChartId.uvb,
      title: 'UVB',
      yAxisTitle: 'µW/cm²',
      data: reshapedData,
      dimension: MeasurableQuantity.uvb,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (uvbChart != null) charts.add(uvbChart);

    final uvcChart = buildMetricChart(
      chartId: ChartSeriesChartId.uvc,
      title: 'UVC',
      yAxisTitle: 'µW/cm²',
      data: reshapedData,
      dimension: MeasurableQuantity.uvc,
      preferences: preferences,
      tripSensors: tripSensors,
    );
    if (uvcChart != null) charts.add(uvcChart);

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
  }) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(dateFormat: DateFormat('MMM d\nHH:mm')),
      primaryYAxis: measurementYAxis(),
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
