import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/controller/app_settings.dart';
import 'package:luftdaten.at/controller/file_handler.dart';
import 'package:luftdaten.at/controller/trip_controller.dart';
import 'package:luftdaten.at/controller/workshop_controller.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/model/trip.dart';
import 'package:luftdaten.at/page/ble_serial_page.dart';
import 'package:luftdaten.at/page/favorites_page.dart';
import 'package:luftdaten.at/page/home_page.i18n.dart';
import 'package:luftdaten.at/page/settings_page.dart';
import 'package:luftdaten.at/widget/change_notifier_builder.dart';
import 'package:luftdaten.at/widget/current_trip_export_dialog.dart';
import 'package:luftdaten.at/widget/file_manager_dialog.dart';
import 'package:luftdaten.at/widget/home_page_battery_icon.dart';
import 'package:luftdaten.at/widget/ui.dart';

import 'chart_page.dart';
import 'dashboard_page.dart';
import 'device_manager_page.dart';
import 'logging_page.dart';
import 'map_page.dart';

class PageViewerPage extends StatefulWidget {
  const PageViewerPage({super.key});

  static const String route = 'pageview';

  @override
  State<PageViewerPage> createState() => _PageViewerPageState();
}

class _PageViewerPageState extends State<PageViewerPage> {
  late PageController _pageController;
  int currentPage = 0;
  bool _skipNextNavigationSelection = false;

  final List<String> _labels = ["Dashboard", "Luftkarte", "Messwerte", "Geräte"];

  final List<IconData> _icons = const [
    Icons.home_outlined,
    Icons.map_outlined,
    Icons.query_stats_outlined,
    Icons.settings_remote_outlined,
  ];

  final List<IconData> _selectedIcons = const [
    Icons.home,
    Icons.map,
    Icons.query_stats,
    Icons.settings_remote,
  ];

  final List<Widget> _pages = const [
    DashboardPage(),
    MapPage(),
    ChartPage(),
    DeviceManagerPage(),
  ];

  @override
  void initState() {
    _pageController = getIt<PageController>();
    super.initState();
  }

  AppBar LDAppBar(BuildContext context, String title) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Workshop running indicator
        ChangeNotifierBuilder(
          notifier: getIt<WorkshopController>(),
          builder: (context, workshopController) {
            workshopController.checkIfWorkshopHasEnded();
            if (workshopController.currentWorkshop == null) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Tooltip(
                message: 'Workshop läuft'.i18n,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    showLDDialog(
                      context,
                      title: 'Workshop läuft'.i18n,
                      icon: Icons.send_to_mobile,
                      text: 'Du sendest Messwerte als Teil des Workshops „%s“. '
                              'Dieser Workshop läuft noch bis %s, %s Uhr.'
                          .i18n
                          .fill(
                        [
                          workshopController.currentWorkshop!.name,
                          DateFormat('dd.MM.yyyy'.i18n)
                              .format(workshopController.currentWorkshop!.end.toLocal()),
                          DateFormat('HH:mm'.i18n)
                              .format(workshopController.currentWorkshop!.end.toLocal()),
                        ],
                      ),
                      actions: [
                        LDDialogAction(
                          label: 'Austreten'.i18n,
                          onTap: () {
                            showLDDialog(
                              context,
                              title: 'Workshop verlassen'.i18n,
                              icon: Icons.exit_to_app,
                              text: 'Aus dem aktuellen Workshop austreten?',
                              color: Colors.red,
                              actions: [
                                LDDialogAction.cancel(),
                                LDDialogAction(
                                  label: 'Austreten'.i18n,
                                  filled: true,
                                  onTap: () {
                                    workshopController.exitWorkshop();
                                  },
                                ),
                              ],
                            );
                          },
                          filled: false,
                        ),
                        LDDialogAction.dismiss(filled: true),
                      ],
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: SpinKitPulsingGrid(color: Colors.yellow, size: 18),
                  ),
                ),
              ),
            );
          },
        ),
        // Battery status of connected device (use first connected device if there are multiple)
        const HomePageBatteryIcon(),
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(value: 'files', child: Text('Gespeicherte Messungen'.i18n)),
            PopupMenuItem(value: 'import', child: Text('Daten importieren'.i18n)),
            if (getIt<TripController>().ongoingTrips.isNotEmpty ||
                getIt<TripController>().loadedTrips.isNotEmpty)
              PopupMenuItem(value: 'export', child: Text('Daten exportieren'.i18n)),
          ],
          tooltip: 'Messdaten verwalten'.i18n,
          onSelected: (val) {
            switch (val) {
              case 'files':
                showFileManagerDialog();
                return;
              case 'import':
                importFile();
                return;
              case 'export':
                shareCurrentTrip();
                return;
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.more_vert),
          ),
        ),
      ],
      title: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset('assets/icon.png', width: 32, height: 32),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(title, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xff2e88c1), //Theme.of(context).colorScheme.primary
    );
  }

  Widget DrawerMenuItem(BuildContext context, Widget mItem, Icon icon, String route,
          String curRoute, int index) =>
      ListTile(
        title: mItem,
        leading: icon,
        selected: route == curRoute,
        onTap: () {
          if (index == -1) {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          } else {
            _pageController.jumpToPage(index);
            Navigator.pop(context);
          }
        },
      );

  Drawer _buildDrawer(BuildContext context, String currentRoute) {
    return Drawer(
      child: ChangeNotifierBuilder(
        notifier: AppSettings.I,
        builder: (context, settings) => ListView(
          children: <Widget>[
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon-round-2.png',
                    height: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Luftdaten.at',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < _labels.length; i++)
              DrawerMenuItem(
                  context, Text(_labels[i].i18n), Icon(_selectedIcons[i]), "", currentRoute, i),
            DrawerMenuItem(context, Text("Favoriten".i18n), const Icon(Icons.bookmark),
                FavoritesPage.route, currentRoute, -1),
            DrawerMenuItem(context, Text("Einstellungen".i18n), const Icon(Icons.settings),
                SettingsPage.route, currentRoute, -1),
            if (settings.useLog)
              DrawerMenuItem(context, Text("Log".i18n), const Icon(Icons.terminal),
                  LoggingPage.route, currentRoute, -1),
            if (settings.showSerialMonitor)
              DrawerMenuItem(
                context,
                Text("Serielle BLE-Konsole".i18n),
                const Icon(Icons.nearby_error),
                BLESerialPage.route,
                currentRoute,
                -1,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: LDAppBar(context, _labels[currentPage].i18n),
        drawer: _buildDrawer(context, PageViewerPage.route),
        body: PageView(
          controller: _pageController,
          onPageChanged: (pageIndex) {
            if (_skipNextNavigationSelection) {
              _skipNextNavigationSelection = false;
              return;
            }
            setState(() {
              currentPage = pageIndex;
            });
          },
          children: _pages,
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: Theme.of(context).navigationBarTheme.copyWith(
              labelTextStyle: MaterialStateProperty.resolveWith(
                (states) {
                  if (states.contains(MaterialState.selected)) {
                    return const TextStyle(
                      fontSize: 13.0,
                      color: Colors.white,
                    );
                  }
                  return const TextStyle(
                    fontSize: 13.0,
                    color: Colors.white70,
                  );
                },
              ),
            ),
          ),
          child: NavigationBar(
            onDestinationSelected: (int idx) {
              _pageController.jumpToPage(idx);
              if ((currentPage - idx).abs() == 2) {
                _skipNextNavigationSelection = true;
              }
              if (kDebugMode) {
                print("$currentPage => $idx");
              }
              setState(() => currentPage = idx);
            },
            backgroundColor: const Color(0xff2e88c1),
            indicatorColor: Colors.white,
            selectedIndex: currentPage,
            surfaceTintColor: Colors.white,
            destinations: [
              for (int i = 0; i < _icons.length; i++)
                NavigationDestination(
                  icon: Icon(_icons[i], color: currentPage == i ? Colors.black : Colors.white70),
                  selectedIcon: Icon(_selectedIcons[i]),
                  label: _labels[i].i18n,
                ),
            ],
          ),
        ),
      );

  void importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
    );
    if (result == null) return;
    File file = File(result.paths.first!);
    if (!mounted) return;
    TripController tripController = getIt<TripController>();
    if (tripController.ongoingTrips.isNotEmpty || tripController.loadedTrips.isNotEmpty) {
      showLDDialog(
        context,
        content: Text(
            'Neu geladene Messpunkte zur aktuellen Anzeige hinzufügen oder aktuelle Anzeige überschreiben?'
                .i18n,
            textAlign: TextAlign.center),
        title: 'Daten hinzufügen',
        icon: Icons.import_export,
        actions: [
          LDDialogAction(
            label: 'Überschreiben'.i18n,
            onTap: () {
              tripController
                ..loadedTrips = []
                ..ongoingTrips = {}
                ..notifyListeners();
              parseFileAndAdd(file);
            },
            filled: false,
          ),
          LDDialogAction(
            label: 'Hinzufügen'.i18n,
            onTap: () => parseFileAndAdd(file),
            filled: true,
          ),
        ],
      );
    } else {
      parseFileAndAdd(file);
    }
  }

  void parseFileAndAdd(File file) async {
    TripController tripController = getIt<TripController>();
    try {
      String extension = file.path.split('.').last;
      String content = file.readAsStringSync();
      if (extension == 'csv') {
        Trip trip = Trip.fromCsv(content);
        tripController.loadedTrips.add(trip);
        tripController.notifyListeners();
      } else if (extension == 'json') {
        Map<String, dynamic> data = json.decode(content);
        String version = data['version'];
        if (version == 'Luftdaten.at JSON Trip v1.0') {
          Trip trip = Trip.fromJson(data);
          tripController.loadedTrips.add(trip);
          tripController.notifyListeners();
        } else if (version == 'Luftdaten.at JSON Collection v1.0') {
          for (Map element in data['trips']) {
            tripController.loadedTrips.add(Trip.fromJson(element.cast<String, dynamic>()));
          }
          tripController.notifyListeners();
        } else {
          throw Exception('Unsupported data encoding: $version');
        }
      } else {
        throw Exception('Unsupported file extension');
      }
    } catch (_) {
      showLDDialog(
        context,
        content: Text('Ein Fehler ist aufgetreten.'.i18n, textAlign: TextAlign.center),
        title: 'Importfehler'.i18n,
        icon: Icons.error,
      );
    }
  }

  void shareCurrentTrip() {
    showDialog(context: context, builder: (_) => const CurrentTripExportDialog());
  }

  void showFileManagerDialog() async {
    List<DateTime> dates = await getIt<FileHandler>().getDatesWithSavedTrips();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => FileManagerDialog(dates),
    );
  }
}
