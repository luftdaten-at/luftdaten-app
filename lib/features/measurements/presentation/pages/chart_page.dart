import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/presentation/pages/chart_page.i18n.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/latest_measurement_layout.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/latest_measurement_panel.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_values_config_dialog.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/sensor_data_point_with_timestamp.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/core/widgets/start_button.dart';
import 'package:provider/provider.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key, this.isFullscreen = false});

  final bool isFullscreen;
  static const String route = 'chart';

  @override
  State<StatefulWidget> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Consumer<TripController>(builder: (context, provider, _) {
            final flattenedData =
                provider.primaryTripToDisplay?.data.map((e) => e.flatten).toList() ?? [];
            if (flattenedData.isEmpty) {
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

            final reshapedDataMap = <LDSensor, List<SensorDataPointWithTimestamp>>{};
            final points = provider.primaryTripToDisplay!.data;
            for (final point in points) {
              for (final sensorData in point.sensorData) {
                reshapedDataMap.putIfAbsent(sensorData.sensor, () => []);
              }
            }
            for (final point in points) {
              for (final sensorData in point.sensorData) {
                reshapedDataMap[sensorData.sensor]!.add(
                  SensorDataPointWithTimestamp(point.timestamp, sensorData),
                );
              }
            }
            final reshapedData = reshapedDataMap.values.toList();
            final tripSensors = reshapedDataMap.keys.toSet();
            final trip = provider.primaryTripToDisplay!;
            final deviceLabel = trip.deviceDisplayName?.trim().isNotEmpty == true
                ? trip.deviceDisplayName!.trim()
                : trip.deviceFourLetterCode ?? 'Unbekanntes Gerät'.i18n;
            final allMetricEntries = MeasurementMetricParser.fromDataPoint(points.last);
            final layout = LatestMeasurementLayout.group(allMetricEntries);
            final batteryData = getIt<BatteryInfoAggregator>().collectedBatteryDetails;
            final availableTiles = LatestMeasurementLayout.availableTiles(
              layout,
              showBattery: AppSettings.I.showBatteryGraph,
              hasBattery: batteryData.isNotEmpty,
            );
            return ChangeNotifierBuilder(
              notifier: getIt<ChartSeriesPreferences>(),
              builder: (context, chartPrefs) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Row(
                          children: [
                            const SizedBox(width: 48),
                            Expanded(
                              child: Text(
                                deviceLabel,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              child: availableTiles.length >= 2
                                  ? IconButton(
                                      icon: const Icon(Icons.tune),
                                      tooltip: 'Messwerte konfigurieren'.i18n,
                                      onPressed: () => showMeasurementTileConfigDialog(
                                        context,
                                        availableTiles: availableTiles,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: LatestMeasurementPanel(
                          latestPoint: points.last,
                          history: points,
                          flattenedData: flattenedData,
                          reshapedData: reshapedData,
                          tripSensors: tripSensors,
                          chartPrefs: chartPrefs,
                        ),
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
}
