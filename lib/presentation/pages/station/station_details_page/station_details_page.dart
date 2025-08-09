import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/ble/ble_device.dart';
import '../../../../core/utils/extensions/list/list_extensions.dart';
import '../../../widgets/common/ui/ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../features/air_station/controllers/air_station_config_wizard_controller.dart';
import '../../../../core/services/network/http/http_provider.dart';
import '../../../widgets/common/change_notifier/change_notifier_builder.dart';
import '../../../../features/air_station/pages/air_station_config_wizard_page.dart';
import 'station_details_page.i18n.dart';
import '../../../../data/models/air_station/air_station_config.dart';

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

  @override
  void initState() {
    String device_id = "";

    if(widget.device != null){
      //device_id = AirStationConfigManager.getConfig(widget.device!.bleName)!.deviceId!;
      // TODO find better Method of getting the Device ID if AirStationConfig is null
      String backupDeviceId = '${widget.device!.bleName.split("-")[1]}AAA';
      device_id = AirStationConfigManager.getConfig(widget.device!.bleName)?.deviceId ?? backupDeviceId;
    }else{
      device_id = widget.id!;
    }

    provider = SingleStationHttpProvider(
      device_id,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
            widget.device != null
                ? widget.device!.displayName
                : 'Station #%s'.i18n.fill([widget.id.toString()]),
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        actions: [
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
            if (!provider.finished) {
              return Center(
                child: SpinKitDualRing(
                  color: Theme.of(context).primaryColor,
                  size: 40,
                  lineWidth: 3,
                ),
              );
            }

            if (provider.items[1].isEmpty || provider.items[2].isEmpty || provider.items[0].isEmpty) {
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

            double? pm1Mean = provider.items[1].first.pm1 != null
                ? provider.items[1].map((e) => e.pm1).toList().removeListNulls().mean()
                : null;
            double? pm25Mean = provider.items[1].where((e) => e.pm25 != null).map((e) => e.pm25!).toList().mean();
            double? pm10Mean = provider.items[1].where((e) => e.pm10 != null).map((e) => e.pm10!).toList().mean();
            List<int> daysOverLimit = getDaysOverLimit(getDailyMeans(provider.items[1]));

            GetStorage box = GetStorage('preferences');
            bool showWHO5 = box.read('station-showWHO5') ?? false;
            bool showWHO15 = box.read('station-showWHO15') ?? false;
            bool showWHO45 = box.read('station-showWHO45') ?? false;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat('MMM d\nHH:mm'),
                    ),
                    title: ChartTitle(text: 'Feinstaubbelastung'.i18n),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(
                        text: 'Konzentration (μg/m³)'.i18n,
                      ),
                      plotBands: [
                        if (showWHO5)
                          const PlotBand(
                            start: 5,
                            end: 5,
                            borderColor: Colors.black,
                            borderWidth: 2,
                          ),
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
                      if (provider.items[selectedIndex].first.pm1 != null)
                        LineSeries<DataItem, DateTime>(
                          dataSource: provider.items[selectedIndex],
                          xValueMapper: (DataItem item, _) => item.timestamp,
                          yValueMapper: (DataItem item, _) => item.pm1,
                          name: 'PM1.0',
                          dataLabelSettings: const DataLabelSettings(isVisible: false),
                        ),
                      LineSeries<DataItem, DateTime>(
                        dataSource: provider.items[selectedIndex],
                        xValueMapper: (DataItem item, _) => item.timestamp,
                        yValueMapper: (DataItem item, _) => item.pm25,
                        name: 'PM2.5',
                        dataLabelSettings: const DataLabelSettings(isVisible: false),
                      ),
                      LineSeries<DataItem, DateTime>(
                        dataSource: provider.items[selectedIndex],
                        xValueMapper: (DataItem item, _) => item.timestamp,
                        yValueMapper: (DataItem item, _) => item.pm10,
                        name: 'PM10.0',
                        dataLabelSettings: const DataLabelSettings(isVisible: false),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Durchschnittswerte der letzten 7 Tage (μg/m³):'.i18n,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        _DataTable(data: [
                          if (pm1Mean != null) ['PM1.0', pm1Mean.toStringAsFixed(2)],
                          ['PM2.5', pm25Mean.toStringAsFixed(2)],
                          ['PM10', pm10Mean.toStringAsFixed(2)],
                        ]),
                        const SizedBox(height: 10),
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
                        if (daysOverLimit[0] > 0 || daysOverLimit[1] > 0) const SizedBox(height: 5),
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
                        const SizedBox(height: 10),
                        Text(
                          'Richtwerte der WHO (μg/m³, Jahresmittel):'.i18n,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        _DataTable(data: [
                          [
                            'PM2.5',
                            '5',
                            _statusDot(pm25Mean <= 5),
                            SizedBox(
                              height: 20,
                              child: IconButton(
                                tooltip: 'Richtwert anzeigen'.i18n,
                                onPressed: () {
                                  setState(() {
                                    showWHO5 = !showWHO5;
                                    box.write('station-showWHO5', showWHO5);
                                  });
                                },
                                icon: Icon(
                                  showWHO5 ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey.shade400,
                                ),
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                          [
                            'PM10',
                            '15',
                            _statusDot(pm10Mean <= 15),
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
                            ),
                          ],
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          'Aktuelle Messwerte (μg/m³):'.i18n,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${"Gemessen".i18n}: ${DateFormat('d.M.y, HH:mm').format(provider.items[1].last.timestamp!.toLocal())}.',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        Text(
                          '(vor %s)'.i18n.fill([
                            durationToString(DateTime.now()
                                .toUtc()
                                .difference(provider.items[1].last.timestamp!.toUtc()))
                          ]),
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 5),
                        _DataTable(data: [
                          if (provider.items[1].last.pm1 != null)
                            ['PM1.0', Text(provider.items[1].last.pm1!.toStringAsFixed(2))],
                          ['PM2.5', Text(provider.items[1].last.pm25!.toStringAsFixed(2))],
                          ['PM10', Text(provider.items[1].last.pm10!.toStringAsFixed(2))],
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  String durationToString(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} sec';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min ${duration.inSeconds % 60} sec';
    }
    return '${duration.inHours} h ${duration.inMinutes % 60} min';
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
