import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:luftdaten.at/features/devices/logic/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/features/map/logic/http_provider.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/air_station_config_wizard_page.dart';
import 'package:luftdaten.at/features/map/presentation/widgets/station_display_name.dart';
import 'package:luftdaten.at/features/map/presentation/widgets/station_favorite_button.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/chart_section.dart';
import 'station_details_page.i18n.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';

class StationDetailsPage extends StatefulWidget {
  const StationDetailsPage({super.key, this.id, this.device, this.httpProvider});

  final String? id;
  final BleDevice? device;
  final SingleStationHttpProvider? httpProvider;

  @override
  State<StatefulWidget> createState() => _StationDetailsPageState();
}

class _StationDetailsPageState extends State<StationDetailsPage> {
  Set<String> period = {'7d'};
  int selectedIndex = 1;

  late SingleStationHttpProvider provider;
  late String deviceId;

  @override
  void initState() {
    String deviceId = "";

    if(widget.device != null){
      //deviceId = AirStationConfigManager.getConfig(widget.device!.bleName)!.deviceId!;
      // TODO find better Method of getting the Device ID if AirStationConfig is null
      String backupDeviceId = '${widget.device!.bleName.split("-")[1]}AAA';
      deviceId = AirStationConfigManager.getConfig(widget.device!.bleName)?.deviceId ?? backupDeviceId;
    }else{
      deviceId = widget.id!;
    }

    if (widget.httpProvider != null && widget.httpProvider!.deviceId == deviceId) {
      provider = widget.httpProvider!;
    } else {
      provider = SingleStationHttpProvider(deviceId);
    }
    this.deviceId = deviceId;
    provider.ensureHistoricalLoaded();

    super.initState();
  }

  Future<LatLng?> _resolveStationLocation() async {
    if (widget.device != null) {
      final config = AirStationConfigManager.getConfig(widget.device!.bleName);
      if (config?.latitude != null && config?.longitude != null) {
        return LatLng(config!.latitude!, config.longitude!);
      }
    }
    if (provider.currentLocation != null) {
      return provider.currentLocation;
    }
    await provider.fetchCurrent();
    return provider.currentLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: widget.device != null
            ? Text(widget.device!.displayName, style: const TextStyle(color: Colors.white))
            : StationDisplayName(
                stationId: deviceId,
                style: const TextStyle(color: Colors.white),
              ),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        actions: [
          StationFavoriteButton(
            deviceId: deviceId,
            iconColor: Colors.white,
            resolveLocation: _resolveStationLocation,
          ),
          if (widget.device != null)
            IconButton(
              onPressed: () {
                showLDDialog(
                  context,
                  title: 'Station neu einrichten'.i18n,
                  icon: Icons.settings_outlined,
                  text: 'Möchtest du die WLAN- oder Messeinstellungen der Air Station neu '
                          'konfigurieren?'
                      .i18n,
                  actions: [
                    LDDialogAction(label: 'Abbrechen'.i18n, filled: false),
                    LDDialogAction(
                      label: 'Konfigurieren'.i18n,
                      filled: true,
                      onTap: () {
                        AirStationConfigWizardController controller =
                            AirStationConfigWizardController(widget.device!.bleName);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => AirStationConfigWizardPage(controller: controller)),
                        );
                      },
                    ),
                  ],
                );
              },
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              tooltip: 'Gerät neu einrichten'.i18n,
            ),
          IconButton(
            onPressed: () {
              if (provider.finished) {
                provider.refetch();
              }
            },
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Synchronisieren'.i18n,
          ),
        ],
      ),
      body: ChangeNotifierBuilder(
          notifier: provider,
          builder: (context, provider) {
            if (!provider.sliceReady[selectedIndex]) {
              return Center(
                child: SpinKitDualRing(
                  color: Theme.of(context).primaryColor,
                  size: 40,
                  lineWidth: 3,
                ),
              );
            }

            if (provider.items[selectedIndex].isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Keine Daten verfügbar.'.i18n),
                      const SizedBox(height: 5),
                      Text(
                        'Tippe auf das Sync-Icon rechts oben, um nach neuen Daten zu suchen.'.i18n,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final weekLoaded = provider.sliceReady[1];
            final weekItems = provider.items[1];
            final selectedItems = provider.items[selectedIndex];

            List<int> daysOverLimit = [0, 0];

            final statsComputed = weekLoaded && weekItems.isNotEmpty;
            if (statsComputed) {
              daysOverLimit = getDaysOverLimit(getDailyMeans(weekItems));
            }

            GetStorage box = GetStorage('preferences');
            bool showWHO15 = box.read('station-showWHO15') ?? false;
            bool showWHO45 = box.read('station-showWHO45') ?? false;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!provider.finished)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        'Weitere Zeiträume werden noch geladen …'.i18n,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                    ),
                  Row(
                    children: [
                      const Spacer(flex: 1),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 10),
                        child: Text('Daten der letzten:'.i18n),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                  Row(
                    children: [
                      const Spacer(flex: 1),
                      SegmentedButton(
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: '24h', label: Text('24 Stunden'.i18n)),
                          ButtonSegment(value: '7d', label: Text('7 Tage'.i18n)),
                          ButtonSegment(value: '1m', label: Text('1 Monat'.i18n)),
                        ],
                        selected: period,
                        multiSelectionEnabled: false,
                        onSelectionChanged: (selection) {
                          setState(() {
                            switch (selection.first) {
                              case '24h':
                                selectedIndex = 0;
                              case '7d':
                                selectedIndex = 1;
                              case '1m':
                              default:
                                selectedIndex = 2;
                            }
                            period = selection;
                          });
                        },
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CenteredChartHeadline(
                        title: _chartHeadline('Feinstaubbelastung', 'μg/m³'),
                      ),
                      _StableStationChart(
                        periodIndex: selectedIndex,
                        items: selectedItems,
                        revision: Object.hash(showWHO15, showWHO45),
                        builder: (items, periodIndex) => SfCartesianChart(
                          key: ValueKey('station-pm-$periodIndex'),
                          enableAxisAnimation: false,
                          primaryXAxis: DateTimeAxis(
                            dateFormat: DateFormat('MMM d\nHH:mm'),
                          ),
                          primaryYAxis: NumericAxis(
                            plotBands: [
                              if (showWHO15)
                                const PlotBand(
                                  start: 15,
                                  end: 15,
                                  borderColor: Colors.black,
                                  borderWidth: 2,
                                ),
                              if (showWHO45)
                                const PlotBand(
                                  start: 45,
                                  end: 45,
                                  borderColor: Colors.black,
                                  borderWidth: 2,
                                ),
                            ],
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
                          series: <CartesianSeries<DataItem, DateTime>>[
                            ..._lineSeriesForDimension(
                              items,
                              periodIndex,
                              (e) => e.pm1,
                              'PM1.0',
                            ),
                            ..._lineSeriesForDimension(
                              items,
                              periodIndex,
                              (e) => e.pm25,
                              'PM2.5',
                            ),
                            ..._lineSeriesForDimension(
                              items,
                              periodIndex,
                              (e) => e.pm10,
                              'PM10.0',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_hasTemperature(selectedItems) || _hasHumidity(selectedItems))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CenteredChartHeadline(
                          title: _environmentChartHeadline(selectedItems),
                        ),
                        _StableStationChart(
                          periodIndex: selectedIndex,
                          items: selectedItems,
                          builder: (items, periodIndex) => SfCartesianChart(
                            key: ValueKey('station-env-$periodIndex'),
                            enableAxisAnimation: false,
                            primaryXAxis: DateTimeAxis(
                              dateFormat: DateFormat('MMM d\nHH:mm'),
                            ),
                            primaryYAxis: const NumericAxis(),
                            axes: <ChartAxis>[
                              if (_hasHumidity(items))
                                const NumericAxis(
                                  name: 'humidityAxis',
                                  opposedPosition: true,
                                ),
                            ],
                            zoomPanBehavior: ZoomPanBehavior(
                              enablePanning: true,
                              enablePinching: true,
                              enableDoubleTapZooming: true,
                              zoomMode: ZoomMode.x,
                              enableSelectionZooming: true,
                            ),
                            legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: <CartesianSeries<DataItem, DateTime>>[
                              ..._lineSeriesForDimension(
                                items,
                                periodIndex,
                                (e) => e.temperature,
                                'Temperatur'.i18n,
                              ),
                              ..._lineSeriesForDimension(
                                items,
                                periodIndex,
                                (e) => e.humidity,
                                'Relative Luftfeuchtigkeit'.i18n,
                                yAxisName: 'humidityAxis',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (_hasPressure(selectedItems))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CenteredChartHeadline(
                          title: _chartHeadline('Luftdruck', 'hPa'),
                        ),
                        _StableStationChart(
                          periodIndex: selectedIndex,
                          items: selectedItems,
                          builder: (items, periodIndex) => SfCartesianChart(
                            key: ValueKey('station-pressure-$periodIndex'),
                            enableAxisAnimation: false,
                            primaryXAxis: DateTimeAxis(
                              dateFormat: DateFormat('MMM d\nHH:mm'),
                            ),
                            primaryYAxis: const NumericAxis(),
                            zoomPanBehavior: ZoomPanBehavior(
                              enablePanning: true,
                              enablePinching: true,
                              enableDoubleTapZooming: true,
                              zoomMode: ZoomMode.x,
                              enableSelectionZooming: true,
                            ),
                            legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: <CartesianSeries<DataItem, DateTime>>[
                              ..._lineSeriesForDimension(
                                items,
                                periodIndex,
                                (e) => e.pressure,
                                'Luftdruck'.i18n,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (statsComputed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Richtwerte der WHO (μg/m³, 24h-Mittel):'.i18n,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          _DataTable(data: [
                            [
                              'PM2.5',
                              '15',
                              _statusDot(daysOverLimit[0] == 0),
                              SizedBox(
                                height: 20,
                                child: IconButton(
                                  tooltip: 'Richtwert anzeigen'.i18n,
                                  onPressed: () {
                                    setState(() {
                                      showWHO15 = !showWHO15;
                                      box.write('station-showWHO15', showWHO15);
                                    });
                                  },
                                  icon: Icon(
                                    showWHO15 ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey.shade400,
                                  ),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              )
                            ],
                            [
                              'PM10',
                              '45',
                              _statusDot(daysOverLimit[1] == 0),
                              SizedBox(
                                height: 20,
                                child: IconButton(
                                  tooltip: 'Richtwert anzeigen'.i18n,
                                  onPressed: () {
                                    setState(() {
                                      showWHO45 = !showWHO45;
                                      box.write('station-showWHO45', showWHO45);
                                    });
                                  },
                                  icon: Icon(
                                    showWHO45 ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey.shade400,
                                  ),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ]),
                          if (daysOverLimit[0] > 0 || daysOverLimit[1] > 0)
                            const SizedBox(height: 5),
                          if (daysOverLimit[0] > 0)
                            Text(
                              'PM2.5 überschritten an %s Tagen/Woche.'.i18n.fill([daysOverLimit[0]]),
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          if (daysOverLimit[1] > 0)
                            Text(
                              'PM10 überschritten an %s Tagen/Woche.'.i18n.fill([daysOverLimit[1]]),
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    )
                  else if (weekLoaded && weekItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Text(
                        'Keine Daten für den 7-Tage‑Zeitraum.'.i18n,
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Statistik wird noch geladen …'.i18n,
                              style:
                                  TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
    );
  }

  String _chartHeadline(String title, String unit) =>
      '%s in %s'.i18n.fill([title.i18n, unit.i18n]);

  List<DataItem> _pointsWithValue(
    List<DataItem> items,
    double? Function(DataItem item) value,
  ) =>
      items.where((item) => value(item) != null).toList();

  Duration _maxGapForPeriod(int index) {
    switch (index) {
      case 0:
        return const Duration(minutes: 90);
      case 1:
        return const Duration(hours: 3);
      default:
        return const Duration(hours: 3);
    }
  }

  List<List<DataItem>> _segmentByTimeGap(List<DataItem> items, Duration maxGap) {
    if (items.isEmpty) return [];
    final sorted = List<DataItem>.from(items)
      ..sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
    final segments = <List<DataItem>>[];
    var current = <DataItem>[sorted.first];
    for (var i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1].timestamp!;
      final next = sorted[i].timestamp!;
      if (next.difference(previous) > maxGap) {
        segments.add(current);
        current = <DataItem>[];
      }
      current.add(sorted[i]);
    }
    segments.add(current);
    return segments;
  }

  List<LineSeries<DataItem, DateTime>> _lineSeriesForDimension(
    List<DataItem> items,
    int periodIndex,
    double? Function(DataItem item) value,
    String name, {
    String? yAxisName,
  }) {
    if (_pointsWithValue(items, value).isEmpty) return [];
    final segments = _segmentByTimeGap(items, _maxGapForPeriod(periodIndex));
    final visibleSegments =
        segments.where((segment) => segment.any((item) => value(item) != null)).toList();
    if (visibleSegments.isEmpty) return [];
    return [
      for (var i = 0; i < visibleSegments.length; i++)
        LineSeries<DataItem, DateTime>(
          animationDuration: 0,
          dataSource: visibleSegments[i],
          xValueMapper: (DataItem item, _) => item.timestamp,
          yValueMapper: (DataItem item, _) => value(item),
          emptyPointSettings: const EmptyPointSettings(mode: EmptyPointMode.gap),
          yAxisName: yAxisName,
          name: name,
          isVisibleInLegend: i == 0,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
    ];
  }

  String _environmentChartHeadline(List<DataItem> items) {
    final hasTemp = _hasTemperature(items);
    final hasHumidity = _hasHumidity(items);
    if (hasTemp && hasHumidity) {
      return _chartHeadline('Temperatur & Luftfeuchtigkeit', '°C und %');
    }
    if (hasTemp) {
      return _chartHeadline('Temperatur', '°C');
    }
    return _chartHeadline('Relative Luftfeuchtigkeit', '%');
  }

  Widget _statusDot(bool withinLimits) {
    return Center(
      child: Tooltip(
        message: withinLimits ? 'Innerhalb des Richtwerts'.i18n : 'Überschreitet Richtwert'.i18n,
        child: Container(
          decoration: BoxDecoration(
            color: withinLimits ? Colors.green : Colors.red,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
          height: 12,
          width: 20,
        ),
      ),
    );
  }

  List<int> getDaysOverLimit(List<List<double>> data) {
    return [
      data.map((e) => e[0]).toList().where((element) => element >= 15).length,
      data.map((e) => e[1]).toList().where((element) => element >= 45).length,
    ];
  }

  List<List<double>> getDailyMeans(List<DataItem> data) {
    List<List<double>> vals = List.filled(7, [0, 0]);
    List<List<DataItem>> itemsPerDay = List.filled(7, []);
    int earliestTime = data.first.timestamp!.millisecondsSinceEpoch;
    for (DataItem item in data) {
      int day =
          ((item.timestamp!.millisecondsSinceEpoch - earliestTime) / (1000 * 60 * 60 * 24)).floor();
      if (day >= 0 && day < 7) {
        itemsPerDay[day].add(item);
      }
    }
    for (int i = 0; i < 7; i++) {
      if (itemsPerDay[i].isEmpty) {
        vals[i] = [0, 0];
      } else {
        vals[i] = [
          itemsPerDay[i].where((e) => e.pm25 != null).map((e) => e.pm25!).toList().mean(),
          itemsPerDay[i].where((e) => e.pm10 != null).map((e) => e.pm10!).toList().mean(),
        ];
      }
    }
    return vals;
  }
}

bool _hasTemperature(List<DataItem> items) => items.any((e) => e.temperature != null);

bool _hasHumidity(List<DataItem> items) => items.any((e) => e.humidity != null);

bool _hasPressure(List<DataItem> items) => items.any((e) => e.pressure != null);

/// Keeps chart widgets from rebuilding when unrelated historical slices finish loading.
class _StableStationChart extends StatefulWidget {
  const _StableStationChart({
    required this.periodIndex,
    required this.items,
    required this.builder,
    this.revision = 0,
  });

  final int periodIndex;
  final List<DataItem> items;
  final int revision;
  final Widget Function(List<DataItem> items, int periodIndex) builder;

  @override
  State<_StableStationChart> createState() => _StableStationChartState();
}

class _StableStationChartState extends State<_StableStationChart> {
  late Widget _cachedChart;

  @override
  void initState() {
    super.initState();
    _cachedChart = widget.builder(widget.items, widget.periodIndex);
  }

  @override
  void didUpdateWidget(covariant _StableStationChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.periodIndex != oldWidget.periodIndex ||
        widget.revision != oldWidget.revision ||
        !identical(widget.items, oldWidget.items)) {
      _cachedChart = widget.builder(widget.items, widget.periodIndex);
    }
  }

  @override
  Widget build(BuildContext context) => _cachedChart;
}

class _DataTable extends StatelessWidget {
  const _DataTable({required this.data});

  final List<List<dynamic>> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data
          .map<Widget>((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: e
                    .map((e) => SizedBox(
                          width: 60,
                          child: e is String ? Text(e, textAlign: TextAlign.center) : e,
                        ))
                    .toList(),
              ))
          .toList()
          .separate(SizedBox(width: data.first.length * 60, child: const Divider())),
    );
  }
}

extension Separate<T> on List<T> {
  List<T> separate(T separator) {
    List<T> list = [this[0]];
    for (T item in getRange(1, length)) {
      list.add(separator);
      list.add(item);
    }
    return list;
  }
}

extension Mean on List<double> {
  double mean() {
    double num = 0;
    for (double item in this) {
      num += item;
    }
    return num / length;
  }
}
