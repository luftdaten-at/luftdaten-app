import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/presentation/pages/chart_page.i18n.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/chart_section.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_values_panel.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/core/widgets/start_button.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key, this.isFullscreen = false});

  final bool isFullscreen;
  static const String route = 'chart';

  @override
  State<StatefulWidget> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Consumer<TripController>(builder: (context, provider, _) {
            List<FlattenedDataPoint> data =
                provider.primaryTripToDisplay?.data.map((e) => e.flatten).toList() ?? [];
            if (data.isEmpty) {
              return ChangeNotifierBuilder(
                  notifier: getIt<DeviceManager>(),
                  builder: (context, deviceManager) {
                    final emptyMessage = deviceManager.devices.where((e) => e.portable).isEmpty
                        ? 'Auf dieser Seite können Messwerte von tragbaren Messgeräten ausgewertet werden. Füge unter „Geräte“ ein tragbares Messgerät hinzu, oder importiere Messdaten aus JSON oder CSV im Menü rechts oben.'
                            .i18n
                        : 'Drücke auf „Messung starten“, um Daten aufzunehmen, oder importiere Messdaten aus früheren Messungen, JSON- oder CSV-Datein im Menü rechts oben.'
                            .i18n;
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  });
            }
            // Reshape data
            Map<LDSensor, List<_SensorDataPointWithTimestamp>> reshapedDataMap = {};
            List<MeasuredDataPoint> points = provider.primaryTripToDisplay!.data;
            // Initialize for all sensors across all points (first point may not have every sensor)
            for (MeasuredDataPoint point in points) {
              for (SensorDataPoint sensorData in point.sensorData) {
                reshapedDataMap.putIfAbsent(sensorData.sensor, () => []);
              }
            }
            for (MeasuredDataPoint point in points) {
              for (SensorDataPoint sensorData in point.sensorData) {
                reshapedDataMap[sensorData.sensor]!.add(_SensorDataPointWithTimestamp(
                  point.timestamp,
                  sensorData,
                ));
              }
            }
            List<List<_SensorDataPointWithTimestamp>> reshapedData =
                reshapedDataMap.values.toList();
            final tripSensors = reshapedDataMap.keys.toSet();
            return ChangeNotifierBuilder(
              notifier: getIt<ChartSeriesPreferences>(),
              builder: (context, chartPrefs) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: MeasurementValuesPanel(
                          point: points.last,
                          tripSensors: tripSensors,
                          layout: MeasurementValuesLayout.appNativeTiles,
                          compact: true,
                          columns: 4,
                          showTimestamp: true,
                        ),
                      ),
                      _buildParticulateChart(data, chartPrefs, tripSensors) ?? const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.temperature,
                            title: 'Temperatur',
                            yAxisTitle: '°C',
                            data: reshapedData,
                            dimension: MeasurableQuantity.temperature,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.humidity,
                            title: 'Luftfeuchtigkeit',
                            yAxisTitle: '%',
                            data: reshapedData,
                            dimension: MeasurableQuantity.humidity,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.voc,
                            title: 'Flüchtige organische Verbindungen (VOC)',
                            yAxisTitle: 'Index (%)',
                            data: reshapedData,
                            dimension: MeasurableQuantity.voc,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.totalVoc,
                            title: 'Flüchtige organische Verbindungen (VOC)',
                            yAxisTitle: 'ppm', // TODO check unit
                            data: reshapedData,
                            dimension: MeasurableQuantity.totalVoc,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.nox,
                            title: 'Stickoxide (NOx)',
                            yAxisTitle: 'Index (%)',
                            data: reshapedData,
                            dimension: MeasurableQuantity.nox,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.pressure,
                            title: 'Luftdruck',
                            yAxisTitle: 'hPa',
                            data: reshapedData,
                            dimension: MeasurableQuantity.pressure,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.co2,
                            title: 'CO₂',
                            yAxisTitle: 'ppm',
                            data: reshapedData,
                            dimension: MeasurableQuantity.co2,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.o3,
                            title: 'O₃',
                            yAxisTitle: 'ppb',
                            data: reshapedData,
                            dimension: MeasurableQuantity.o3,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.aqi,
                            title: 'Air Quality Index',
                            yAxisTitle: 'Index',
                            data: reshapedData,
                            dimension: MeasurableQuantity.aqi,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      _buildChart(
                            chartId: ChartSeriesChartId.gasResistance,
                            title: 'Gaswiderstand',
                            yAxisTitle: 'Index',
                            data: reshapedData,
                            dimension: MeasurableQuantity.gasResistance,
                            preferences: chartPrefs,
                            tripSensors: tripSensors,
                          ) ??
                          const SizedBox(),
                      ChangeNotifierBuilder(
                        notifier: AppSettings.I,
                        builder: (context, appSettings) {
                          if (appSettings.showBatteryGraph) {
                            return _buildBatteryChart(false) ?? const SizedBox();
                          }
                          return const SizedBox();
                        },
                      ),
                      ChangeNotifierBuilder(
                        notifier: AppSettings.I,
                        builder: (context, appSettings) {
                          if (appSettings.showBatteryGraph) {
                            return _buildBatteryChart(true) ?? const SizedBox();
                          }
                          return const SizedBox();
                        },
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                );
              },
            );
          }),
          if (!widget.isFullscreen)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: StartButton(page: 'charts'),
              ),
            ),
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > constraints.maxHeight || widget.isFullscreen) {
              return SafeArea(
                bottom: false,
                right: false,
                top: widget.isFullscreen,
                left: widget.isFullscreen,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton.filledTonal(
                    onPressed: () {
                      if (widget.isFullscreen) {
                        Navigator.pop(context);
                      } else {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ChartPage(isFullscreen: true)));
                      }
                    },
                    icon: Icon(widget.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                    tooltip:
                        widget.isFullscreen ? 'Vollbildmodus beenden'.i18n : 'Vollbildmodus'.i18n,
                  ),
                ),
              );
            }
            return const SizedBox(height: 0, width: 0);
          }),
        ],
      ),
    );
  }

  Widget? _buildParticulateChart(
    List<FlattenedDataPoint> data,
    ChartSeriesPreferences preferences,
    Set<LDSensor> tripSensors,
  ) {
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
        xValueMapper: (FlattenedDataPoint item, _) => item.timestamp,
        yValueMapper: (FlattenedDataPoint item, _) => item.pm1,
        name: 'PM1.0',
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (data.first.pm25 != null &&
        preferences.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm25)) {
      series.add(LineSeries<FlattenedDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (FlattenedDataPoint item, _) => item.timestamp,
        yValueMapper: (FlattenedDataPoint item, _) => item.pm25,
        name: 'PM2.5',
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (data.first.pm4 != null &&
        preferences.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm4)) {
      series.add(LineSeries<FlattenedDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (FlattenedDataPoint item, _) => item.timestamp,
        yValueMapper: (FlattenedDataPoint item, _) => item.pm4,
        name: 'PM4.0',
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (data.first.pm10 != null &&
        preferences.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm10)) {
      series.add(LineSeries<FlattenedDataPoint, DateTime>(
        dataSource: data,
        xValueMapper: (FlattenedDataPoint item, _) => item.timestamp,
        yValueMapper: (FlattenedDataPoint item, _) => item.pm10,
        name: 'PM10.0',
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (series.isEmpty) return null;

    return ChartSection(
      title: _chartHeadline('Feinstaubbelastung', 'μg/m³'),
      chartId: ChartSeriesChartId.particulate,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('MMM d\nHH:mm'),
        ),
        primaryYAxis: _measurementYAxis(),
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
      ),
    );
  }

  Widget? _buildChart({
    required ChartSeriesChartId chartId,
    required String title,
    required String yAxisTitle,
    required List<List<_SensorDataPointWithTimestamp>> data,
    required MeasurableQuantity dimension,
    required ChartSeriesPreferences preferences,
    required Set<LDSensor> tripSensors,
  }) {
    List<List<_SensorDataPointWithTimestamp>> qualifyingData =
        data.where((e) => e.firstOrNull?.data.values.containsKey(dimension) ?? false).toList();
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

    List<LineSeries> series = [];
    for (List<_SensorDataPointWithTimestamp> sensorData in qualifyingData) {
      final sensorKey = sensorData.first.data.sensor.name;
      if (!preferences.isVisible(chartId, sensorKey, tripSensors: tripSensors)) continue;
      series.add(LineSeries<_SensorDataPointWithTimestamp, DateTime>(
        dataSource: sensorData,
        xValueMapper: (_SensorDataPointWithTimestamp item, _) => item.timestamp,
        yValueMapper: (_SensorDataPointWithTimestamp item, _) => item.data.values[dimension]!,
        name: sensorData.first.data.sensor.shortName,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (qualifyingData.length > 1 &&
        preferences.isVisible(chartId, ChartSeriesKeys.mean, tripSensors: tripSensors)) {
      List<_SensorDataPointWithTimestamp> meanData = [];
      for (int i = 0; i < qualifyingData.first.length; i++) {
        double sum = 0;
        for (List<_SensorDataPointWithTimestamp> sensorData in qualifyingData) {
          sum += sensorData[i].data.values[dimension]!;
        }
        meanData.add(_SensorDataPointWithTimestamp(
          qualifyingData.first[i].timestamp,
          SensorDataPoint(sensor: LDSensor.all, values: {dimension: sum / qualifyingData.length}),
        ));
      }
      series.add(LineSeries<_SensorDataPointWithTimestamp, DateTime>(
        dataSource: meanData,
        xValueMapper: (_SensorDataPointWithTimestamp item, _) => item.timestamp,
        yValueMapper: (_SensorDataPointWithTimestamp item, _) => item.data.values[dimension]!,
        name: 'Mittelwert'.i18n,
        width: 4,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (series.isEmpty) return null;

    return ChartSection(
      title: _chartHeadline(title, yAxisTitle),
      chartId: chartId,
      seriesOptions: options,
      tripSensors: tripSensors,
      chart: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('MMM d\nHH:mm'),
        ),
        primaryYAxis: _measurementYAxis(),
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
      ),
    );
  }

  String _chartHeadline(String title, String unit) =>
      '%s in %s'.i18n.fill([title.i18n, unit.i18n]);

  NumericAxis _measurementYAxis() => const NumericAxis();

  Widget? _buildBatteryChart(bool voltage) {
    final headline = voltage
        ? _chartHeadline('Batteriestatus', '%')
        : _chartHeadline('Batteriespannung', 'V');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CenteredChartHeadline(title: headline),
        SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('MMM d\nHH:mm'),
      ),
      primaryYAxis: _measurementYAxis(),
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
          dataSource: getIt<BatteryInfoAggregator>().collectedBatteryDetails,
          xValueMapper: (BatteryDetails item, _) => item.timestamp,
          yValueMapper: (BatteryDetails item, _) => voltage ? item.percentage : item.voltage,
          name: 'Batteriestatus'.i18n,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
      ],
        ),
      ],
    );
  }
}

class _SensorDataPointWithTimestamp {
  _SensorDataPointWithTimestamp(this.timestamp, this.data);

  final DateTime timestamp;
  final SensorDataPoint data;
}
