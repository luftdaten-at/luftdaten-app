import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/controller/battery_info_aggregator.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/core/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/measurement/controllers/trip_controller.dart';
import 'package:luftdaten.at/features/measurement/models/measured_data.dart';
import 'package:luftdaten.at/features/measurement/pages/chart_page.i18n.dart';
import 'package:luftdaten.at/model/battery_details.dart';
import 'package:luftdaten.at/shared/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/shared/widgets/start_button.dart';
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
                    if (deviceManager.devices.where((e) => e.portable).isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            'Auf dieser Seite können Messwerte von tragbaren Messgeräten ausgewertet werden. Füge unter „Geräte“ ein tragbares Messgerät hinzu, oder importiere Messdaten aus JSON oder CSV im Menü rechts oben.'
                                .i18n,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            'Drücke auf „Messung starten“, um Daten aufzunehmen, oder importiere Messdaten aus früheren Messungen, JSON- oder CSV-Datein im Menü rechts oben.'
                                .i18n,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                  });
            }
            // Reshape data
            Map<LDSensor, List<_SensorDataPointWithTimestamp>> reshapedDataMap = {};
            List<MeasuredDataPoint> points = provider.primaryTripToDisplay!.data;
            for (LDSensor sensor in points.first.sensorData.map((e) => e.sensor)) {
              reshapedDataMap[sensor] = [];
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
            return SingleChildScrollView(
              child: Column(
                children: [
                  if (data.firstOrNull?.pm1 != null ||
                      data.firstOrNull?.pm25 != null ||
                      data.firstOrNull?.pm4 != null ||
                      data.firstOrNull?.pm10 != null)
                    SfCartesianChart(
                      primaryXAxis: DateTimeAxis(
                        dateFormat: DateFormat('MMM d\nHH:mm'),
                      ),
                      title: ChartTitle(text: 'Feinstaubbelastung'.i18n),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(
                          text: 'Konzentration (μg/m³)'.i18n,
                        ),
                      ),
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePanning: true,
                        enablePinching: true,
                        enableDoubleTapZooming: true,
                        zoomMode: ZoomMode.x,
                        enableSelectionZooming: true,
                      ),
                      legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries<FlattenedDataPoint, DateTime>>[
                        if (data.first.pm1 != null)
                          LineSeries<FlattenedDataPoint, DateTime>(
                            dataSource: data,
                            xValueMapper: (FlattenedDataPoint item, _) => item.timestamp,
                            yValueMapper: (FlattenedDataPoint item, _) => item.pm1,
                            name: 'PM1.0',
                            dataLabelSettings: const DataLabelSettings(isVisible: false),
                          ),
                        if (data.first.pm25 != null)
                          LineSeries<FlattenedDataPoint, DateTime>(
                            dataSource: data,
                            xValueMapper: (FlattenedDataPoint item, _) => item.timestamp,
                            yValueMapper: (FlattenedDataPoint item, _) => item.pm25,
                            name: 'PM2.5',
                            dataLabelSettings: const DataLabelSettings(isVisible: false),
                          ),
                        if (data.first.pm4 != null)
                          LineSeries<FlattenedDataPoint, DateTime>(
                            dataSource: data,
                            xValueMapper: (FlattenedDataPoint item, _) => item.timestamp,
                            yValueMapper: (FlattenedDataPoint item, _) => item.pm4,
                            name: 'PM4.0',
                            dataLabelSettings: const DataLabelSettings(isVisible: false),
                          ),
                        if (data.first.pm10 != null)
                          LineSeries<FlattenedDataPoint, DateTime>(
                            dataSource: data,
                            xValueMapper: (FlattenedDataPoint item, _) => item.timestamp,
                            yValueMapper: (FlattenedDataPoint item, _) => item.pm10,
                            name: 'PM10.0',
                            dataLabelSettings: const DataLabelSettings(isVisible: false),
                          ),
                      ],
                    ),
                  _buildChart(
                        title: 'Temperatur',
                        yAxisTitle: '°C',
                        data: reshapedData,
                        dimension: MeasurableQuantity.temperature,
                      ) ??
                      const SizedBox(),
                  _buildChart(
                        title: 'Luftfeuchtigkeit',
                        yAxisTitle: '%',
                        data: reshapedData,
                        dimension: MeasurableQuantity.humidity,
                      ) ??
                      const SizedBox(),
                  _buildChart(
                        title: 'Flüchtige organische Verbindungen (VOC)',
                        yAxisTitle: 'Index (%)',
                        data: reshapedData,
                        dimension: MeasurableQuantity.voc,
                      ) ??
                      const SizedBox(),
                  _buildChart(
                        title: 'Flüchtige organische Verbindungen (VOC)',
                        yAxisTitle: 'ppm', // TODO check unit
                        data: reshapedData,
                        dimension: MeasurableQuantity.totalVoc,
                      ) ??
                      const SizedBox(),
                  _buildChart(
                        title: 'Stickoxide (NOx)',
                        yAxisTitle: 'Index (%)',
                        data: reshapedData,
                        dimension: MeasurableQuantity.nox,
                      ) ??
                      const SizedBox(),
                  _buildChart(
                        title: 'Luftdruck',
                        yAxisTitle: 'hPa',
                        data: reshapedData,
                        dimension: MeasurableQuantity.pressure,
                      ) ??
                      const SizedBox(),
                  _buildChart(
                        title: 'CO₂',
                        yAxisTitle: 'ppm',
                        data: reshapedData,
                        dimension: MeasurableQuantity.co2,
                      ) ??
                      const SizedBox(),
                  _buildChart(
                        title: 'O₃',
                        yAxisTitle: 'ppb',
                        data: reshapedData,
                        dimension: MeasurableQuantity.o3,
                      ) ??
                      const SizedBox(),
                  _buildChart(
                        title: 'Air Quality Index',
                        yAxisTitle: 'Index',
                        data: reshapedData,
                        dimension: MeasurableQuantity.aqi,
                      ) ??
                      const SizedBox(),
                  _buildChart(
                        title: 'Gaswiderstand',
                        yAxisTitle: 'Index',
                        data: reshapedData,
                        dimension: MeasurableQuantity.gasResistance,
                      ) ??
                      const SizedBox(),
                  // Battery percentage chart
                  ChangeNotifierBuilder(
                    notifier: AppSettings.I,
                    builder: (context, appSettings) {
                      if (appSettings.showBatteryGraph) {
                        return _buildBatteryChart(false) ?? const SizedBox();
                      }
                      return const SizedBox();
                    },
                  ),
                  // Battery voltage chart
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

  Widget? _buildChart({
    required String title,
    required String yAxisTitle,
    required List<List<_SensorDataPointWithTimestamp>> data,
    required MeasurableQuantity dimension,
  }) {
    // Data must be sorted in one list per reporting sensor
    // Safe to call if dimension is not in data
    List<List<_SensorDataPointWithTimestamp>> qualifyingData =
        data.where((e) => e.firstOrNull?.data.values.containsKey(dimension) ?? false).toList();
    if (qualifyingData.isEmpty) return null;
    List<LineSeries> series = [];
    for (List<_SensorDataPointWithTimestamp> sensorData in qualifyingData) {
      series.add(LineSeries<_SensorDataPointWithTimestamp, DateTime>(
        dataSource: sensorData,
        xValueMapper: (_SensorDataPointWithTimestamp item, _) => item.timestamp,
        yValueMapper: (_SensorDataPointWithTimestamp item, _) => item.data.values[dimension]!,
        name: sensorData.first.data.sensor.shortName,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    if (qualifyingData.length > 1) {
      // Add mean
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
        name: 'Mittelwert',
        width: 4,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
      ));
    }
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('MMM d\nHH:mm'),
      ),
      title: ChartTitle(text: title.i18n),
      primaryYAxis: NumericAxis(
        title: AxisTitle(
          text: yAxisTitle.i18n,
        ),
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
        enableDoubleTapZooming: true,
        zoomMode: ZoomMode.x,
        enableSelectionZooming: true,
      ),
      legend: const Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: series,
    );
  }

  Widget? _buildBatteryChart(bool voltage) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('MMM d\nHH:mm'),
      ),
      title: ChartTitle(text: 'Batteriestatus'.i18n),
      primaryYAxis: NumericAxis(
        title: AxisTitle(
          text: voltage ? 'Ladestatus (%)'.i18n : 'Batteriespannung (V)'.i18n,
        ),
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
        enableDoubleTapZooming: true,
        zoomMode: ZoomMode.x,
        enableSelectionZooming: true,
      ),
      legend: const Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        LineSeries<BatteryDetails, DateTime>(
          dataSource: getIt<BatteryInfoAggregator>().collectedBatteryDetails,
          xValueMapper: (BatteryDetails item, _) => item.timestamp,
          yValueMapper: (BatteryDetails item, _) => voltage ? item.percentage : item.voltage,
          name: 'Batteriestatus',
          dataLabelSettings: const DataLabelSettings(isVisible: false),
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
