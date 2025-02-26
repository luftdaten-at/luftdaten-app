/*
   Copyright (C) 2023 Thomas Ogrisegg for luftdaten.at

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

 */
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/controller/app_settings.dart';
import 'package:luftdaten.at/controller/favorites_manager.dart';
import 'package:luftdaten.at/controller/preferences_handler.dart';
import 'package:luftdaten.at/controller/toaster.dart';
import 'package:luftdaten.at/controller/trip_controller.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/model/measured_data.dart';
import 'package:luftdaten.at/page/annotated_picture_page.dart';
import 'package:luftdaten.at/page/map_page.i18n.dart';
import 'package:luftdaten.at/page/station_details_page.dart';
import 'package:luftdaten.at/util/gradient_color.dart';
import 'package:luftdaten.at/widget/change_notifier_builder.dart';
import 'package:luftdaten.at/widget/marker_dialog.dart';
import 'package:luftdaten.at/widget/start_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../controller/http_provider.dart';
import '../model/trip.dart';
import '../model/value_marker.dart';
import '../widget/progress.dart';
import '../widget/ui.dart';
import 'package:luftdaten.at/enums.dart' as enums;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  static const String route = 'map';

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimatedMapController _controller = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );
  StreamSubscription? _mapMovedSubscription;
  double _zoom = 11.2;
  final MarkerDialogController _markerDialogController = MarkerDialogController();

  int stationsLength = 0;
  List<Marker> historyMarkers = [];
  late TextEditingController _textController;
  final TripController router = getIt<TripController>();
  int primaryItem = 5; // = PM10.0

  bool autoCenter = true;

  int mapDisplayType = enums.Dimension.PM2_5;

  final CompassController _compassController = CompassController();

  Color getLDColor(MeasuredDataPoint item) {
    //if (item.flatten.pm10 != null) {
    //  return FormattedValue.from(MeasurableQuantity.pm10, item.flatten.pm10!).color;
    //}
    if (mapDisplayType == enums.Dimension.PM1_0) {
      if (item.flatten.pm1 == null) return Colors.grey;
      return GradientColor.pm1().getColor(item.flatten.pm1!);
    } else if (mapDisplayType == enums.Dimension.PM2_5) {
      if (item.flatten.pm25 == null) return Colors.grey;
      return GradientColor.pm25().getColor(item.flatten.pm25!);
    } else if (mapDisplayType == enums.Dimension.PM10_0) {
      if (item.flatten.pm10 == null) return Colors.grey;
      return GradientColor.pm10().getColor(item.flatten.pm10!);
    } else if (mapDisplayType == enums.Dimension.TEMPERATURE) {
      if (item.flatten.temperature == null) return Colors.grey;
      return GradientColor.temperature().getColor(item.flatten.temperature!);
    }
    return Colors.blue;
  }

  void updateStations({bool zoomin = false, MapEvent? event}) {
    getIt<MapHttpProvider>().fetch();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    logger.d("MapPage: initState()");
    _textController = TextEditingController();
    mapDisplayType = getIt<PreferencesHandler>().selectedPM;
  }

  @override
  void dispose() {
    _textController.dispose();
    _mapMovedSubscription?.cancel();
    super.dispose();
  }

  void showStationDialog(DataLocationItem item) {
    SingleStationHttpProvider provider = SingleStationHttpProvider(item.device_id.toString());
    showLDDialog(
      context,
      title: "Station #%s".i18n.fill([item.device_id.toString()]),
      trailing: StatefulBuilder(builder: (_, setState) {
        FavoritesManager favoritesManager = getIt<FavoritesManager>();
        bool selected = favoritesManager.hasId(item.device_id);
        return IconButton(
          tooltip: selected ? 'Aus Favoriten entfernen'.i18n : 'Zu Favoriten hinzufügen'.i18n,
          onPressed: () async {
            if (selected) {
              favoritesManager.removeId(item.device_id);
              setState(() {});
            } else {
              Favorite favorite =
                  Favorite(id: item.device_id, latLng: LatLng(item.latitude, item.longitude));
              favoritesManager.add(favorite);
              setState(() {});
              await setLocaleIdentifier(locale ?? 'de');
              List<Placemark> placemarks = await placemarkFromCoordinates(
                item.latitude,
                item.longitude,
              );
              logger.d('Reverse geocoding result:');
              for (Placemark placemark in placemarks) {
                logger.d(placemark.toString());
              }
              if (placemarks.firstOrNull != null) {
                Placemark placemark = placemarks.first;
                if (placemark.thoroughfare != null &&
                    placemark.postalCode != null &&
                    placemark.administrativeArea != null) {
                  String locationString =
                      '${placemark.thoroughfare}, ${placemark.postalCode} ${placemark.administrativeArea}';
                  favorite.locationString = locationString;
                  logger.d('Formatted location: $locationString');
                }
              }
            }
          },
          icon: Icon(selected ? Icons.bookmark_added : Icons.bookmark_add_outlined),
        );
      }),
      icon: Icons.air,
      content: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.shortestSide - 80,
          width: MediaQuery.of(context).size.shortestSide - 80,
          child: ChangeNotifierBuilder(
            notifier: provider,
            builder: (ctx, provider) {
              if (!provider.finished) {
                return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [const ProgressWaiter(), Text("Lade Daten von Server".i18n)]);
              }
              if (provider.items.isEmpty) {
                return Text("Keine Daten verfügbar".i18n);
              }
              return SfCartesianChart(
                primaryXAxis: DateTimeAxis(dateFormat: DateFormat('MMM d\nHH:mm')),
                title: ChartTitle(text: 'Feinstaubbelastung (μg/m³)'.i18n),
                legend: const Legend(isVisible: true),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<DataItem, DateTime>>[
                  if (provider.items[1][0].pm1 != null)
                    LineSeries<DataItem, DateTime>(
                      dataSource: provider.items[1],
                      xValueMapper: (DataItem item, _) => item.timestamp,
                      yValueMapper: (DataItem item, _) => item.pm1,
                      name: 'PM1.0',
                      dataLabelSettings: const DataLabelSettings(isVisible: false),
                    ),
                  LineSeries<DataItem, DateTime>(
                    dataSource: provider.items[1],
                    xValueMapper: (DataItem item, _) => item.timestamp,
                    yValueMapper: (DataItem item, _) => item.pm25,
                    name: 'PM2.5',
                    dataLabelSettings: const DataLabelSettings(isVisible: false),
                  ),
                  LineSeries<DataItem, DateTime>(
                    dataSource: provider.items[1],
                    xValueMapper: (DataItem item, _) => item.timestamp,
                    yValueMapper: (DataItem item, _) => item.pm10,
                    name: 'PM10.0',
                    dataLabelSettings: const DataLabelSettings(isVisible: false),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        LDDialogAction(
            label: 'Details'.i18n,
            filled: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StationDetailsPage(
                    id: item.device_id,
                    httpProvider: provider,
                  ),
                ),
              );
            }),
        LDDialogAction(label: 'Schließen'.i18n, filled: true),
      ],
    );
  }

  Marker? getHistoryMarker(MeasuredDataPoint item) {
    if (item.location == null) return null;
    return Marker(
      point: LatLng(item.location!.latitude, item.location!.longitude),
      width: 42,
      height: 42,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Container(
          decoration: BoxDecoration(
            color: getLDColor(item),
            borderRadius: BorderRadius.circular(5),
          ),
          width: 10,
          height: 10,
        ),
        onPressed: () => showMarkerDialog(item),
      ),
    );
  }

  void showMarkerDialog(MeasuredDataPoint item, {bool isInfo = false}) {
    List<FormattedValue> maps = FormattedValue.fromDataPoint(item);

    showLDDialog(
      context,
      title: isInfo ? "Letzte Messwerte" : "Messdaten".i18n,
      icon: Icons.stacked_line_chart,
      content: MarkerDialog(
          values: maps, item: item, controller: _markerDialogController, isInfo: isInfo),
      actions: [
        LDDialogAction.dismiss(),
        if (!isInfo)
          LDDialogAction(
              label: 'Speichern'.i18n,
              filled: true,
              onTap: () {
                _markerDialogController.saveChanges();
              }),
      ],
    );
  }

  void updateZoom(double inc) {
    _zoom = _controller.mapController.camera.zoom;
    _zoom += inc;
    if (_zoom > 18.0) {
      _zoom = 18.0;
    } else if (_zoom < 0.0) {
      _zoom = 0.0;
    }
    _controller.animateTo(zoom: _zoom);
  }

  void updateGPS({double newZoom = 0.0}) async {
    var position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    logger.d("Position: $position, ${_controller.mapController.camera.center}");
    _controller.animateTo(dest: LatLng(position.latitude, position.longitude), zoom: 17);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: FlutterMap(
        mapController: _controller.mapController,
        options: MapOptions(
          initialCenter: const LatLng(48.21919466912646, 16.383482313924404),
          initialZoom: _zoom,
          maxZoom: 18,
          onMapReady: () {
            _mapMovedSubscription =
                _controller.mapController.mapEventStream.listen((MapEvent mapEvent) {
              if (mapEvent is MapEventRotate) {
                double rotation = mapEvent.camera.rotation;
                _compassController.bearing.value = rotation;
              }
              if (mapEvent is MapEventRotateEnd) {
                double rotation = mapEvent.camera.rotation;
                bool showCompass = rotation != 0.0;
                if (showCompass != _compassController.showCompass.value) {
                  _compassController.showCompass.value = showCompass;
                }
              }
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'at.luftdaten.pmble',
          ),
          ChangeNotifierBuilder(
              notifier: AppSettings.I,
              builder: (context, settings) {
                if (!settings.showOverlay) return const SizedBox();
                return MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 45,
                    size: const Size(44, 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: 15,
                    markers: context
                        .watch<MapHttpProvider>()
                        .allItems
                        .map(
                          (e) => ValueMarker<StationPM>(
                            point: LatLng(e.latitude, e.longitude),
                            value: StationPM(pm1: e.pm1, pm25: e.pm25, pm10: e.pm10),
                            width: 40,
                            height: 40,
                            child: IconButton(
                              onPressed: () => showStationDialog(e),
                              iconSize: 40,
                              padding: EdgeInsets.zero,
                              icon: Builder(builder: (context) {
                                double? value;
                                if (mapDisplayType == enums.Dimension.PM1_0) value = e.pm1;
                                if (mapDisplayType == enums.Dimension.PM2_5) value = e.pm25;
                                if (mapDisplayType == enums.Dimension.PM10_0) value = e.pm10;
                                if (value?.isNaN ?? false) value = null;
                                Color color;
                                if (value != null) {
                                  var [r, g, b] = enums.Dimension.getColor(mapDisplayType, value);
                                  color = Color.fromRGBO(r, g, b, 1);
                                } else {
                                  color = Colors.grey;
                                }
                                return Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: color,
                                  ),
                                  child: Center(
                                    child: Text(
                                      value != null
                                          ? value.toStringAsFixed(value <= 99.9 ? 1 : 0)
                                          : '',
                                      style: TextStyle(
                                        color: color.computeLuminance() > 0.179
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        )
                        .toList(),
                    builder: (context, markers) {
                      double acc = 0;
                      int count = 0;
                      for (Marker marker in markers) {
                        StationPM stationPM = (marker as ValueMarker).value as StationPM;
                        double? value;
                        if (mapDisplayType == enums.Dimension.PM1_0) value = stationPM.pm1;
                        if (mapDisplayType == enums.Dimension.PM2_5) value = stationPM.pm25;
                        if (mapDisplayType == enums.Dimension.PM10_0) value = stationPM.pm10;
                        if (mapDisplayType == enums.Dimension.TEMPERATURE) value = null;
                        if (value != null && !value.isNaN) {
                          acc += value;
                          count++;
                        }
                      }
                      double? value = count == 0 ? null : acc / count;
                      Color color;
                      if (value != null) {
                        GradientColor gradient;
                        if (mapDisplayType == enums.Dimension.PM1_0) {
                          gradient = GradientColor.pm1();
                        } else if (mapDisplayType == enums.Dimension.PM2_5) {
                          gradient = GradientColor.pm25();
                        } else {
                          gradient = GradientColor.pm10();
                        }
                        color = gradient.getColor(value);
                      } else {
                        color = Colors.grey;
                      }
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: color,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            value != null ? value.toStringAsFixed(value <= 99.9 ? 1 : 0) : '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color.computeLuminance() > 0.179 ? Colors.black : Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
          IgnorePointer(child: CurrentLocationLayer()),
          Consumer<TripController>(
            builder: (ctx, tripController, _) {
              Trip? current = tripController.primaryTripToDisplay; // TODO support multiple trips
              if (autoCenter &&
                  current != null &&
                  !current.isImported &&
                  current.data.lastOrNull?.location != null) {
                Future.delayed(const Duration(milliseconds: 10)).then((_) {
                  if (AppSettings.I.followUserDuringMeasurements) {
                    _controller.animateTo(
                      dest: current.data.lastOrNull!.location!,
                      zoom: 17,
                    );
                  }
                });
              }
              return MarkerLayer(
                markers:
                    (current?.data ?? []).map((e) => getHistoryMarker(e)).toList().removeNulls(),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ChangeNotifierBuilder(
                  notifier: AppSettings.I,
                  builder: (context, settings) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (settings.showZoomButtons)
                          IconButton.filled(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Colors.white),
                              elevation: WidgetStateProperty.all(2),
                              shadowColor: WidgetStateProperty.all(Colors.black),
                            ),
                            tooltip: 'Vergrößern'.i18n,
                            color: Colors.black,
                            onPressed: () => updateZoom(0.5),
                            icon: const Icon(Icons.zoom_in_outlined),
                            padding: const EdgeInsets.all(10),
                          ),
                        if (settings.showZoomButtons) const SizedBox(height: 5),
                        if (settings.showZoomButtons)
                          IconButton.filled(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Colors.white),
                              elevation: WidgetStateProperty.all(2),
                              shadowColor: WidgetStateProperty.all(Colors.black),
                            ),
                            tooltip: 'Verkleinern'.i18n,
                            color: Colors.black,
                            onPressed: () => updateZoom(-0.5),
                            icon: const Icon(Icons.zoom_out_outlined),
                            padding: const EdgeInsets.all(10),
                          ),
                        if (settings.showZoomButtons) const SizedBox(height: 5),
                        if (settings.showNotesButton)
                          IconButton.filled(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Colors.white),
                              elevation: WidgetStateProperty.all(2),
                              shadowColor: WidgetStateProperty.all(Colors.black),
                            ),
                            color: Colors.black,
                            onPressed: () {
                              TripController tripController = context.read<TripController>();
                              Trip? trip = tripController.primaryTripToDisplay;
                              if (trip?.data.lastOrNull != null) {
                                showMarkerDialog(trip!.data.last);
                              } else {
                                showLDDialog(
                                  context,
                                  text: 'Messung starten, um Notizen zu einem Messwert hizuzufügen.'
                                      .i18n,
                                  title: 'Keine Messungen vorhanden'.i18n,
                                  icon: Icons.error_outline,
                                  color: Colors.red,
                                );
                              }
                            },
                            icon: const Icon(Icons.draw),
                            padding: const EdgeInsets.all(10),
                            tooltip: 'Notiz hinzufügen'.i18n,
                          ),
                        if (settings.showNotesButton) const SizedBox(height: 5),
                        if (settings.showCameraButton)
                          IconButton.filled(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(Colors.white),
                              elevation: WidgetStateProperty.all(2),
                              shadowColor: WidgetStateProperty.all(Colors.black),
                            ),
                            tooltip: 'Foto hinzufügen'.i18n,
                            color: Colors.black,
                            onPressed: () async {
                              Permission cameraPermission = Permission.camera;
                              if (await cameraPermission.isGranted) {
                                if (!context.mounted) return;
                                Navigator.of(context).pushNamed(AnnotatedPicturePage.route);
                              } else {
                                if (!context.mounted) return;
                                showLDDialog(
                                  context,
                                  content: Text(
                                    'Um Fotos aufzunehmen, ist die Kamera-Berechtigung benötigt.'
                                        .i18n,
                                    textAlign: TextAlign.center,
                                  ),
                                  title: 'Kamera-Berechtigung'.i18n,
                                  icon: Icons.camera_alt,
                                  actions: [
                                    LDDialogAction(label: 'Abbrechen'.i18n, filled: false),
                                    LDDialogAction(
                                      label: 'Anfragen'.i18n,
                                      filled: true,
                                      onTap: () {
                                        cameraPermission.request().then((status) {
                                          if (status == PermissionStatus.granted) {
                                            Navigator.of(context)
                                                .pushNamed(AnnotatedPicturePage.route);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                );
                              }
                            },
                            icon: const Icon(Icons.camera_alt_outlined),
                            padding: const EdgeInsets.all(10),
                          ),
                        if (settings.showCameraButton) const SizedBox(height: 5),
                        IconButton.filled(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.white),
                            elevation: WidgetStateProperty.all(2),
                            shadowColor: WidgetStateProperty.all(Colors.black),
                          ),
                          tooltip: 'Auf Standort zentrieren'.i18n,
                          color: Colors.black,
                          onPressed: () => updateGPS(),
                          icon: const Icon(Icons.location_searching),
                          padding: const EdgeInsets.all(10),
                        ),
                      ],
                    );
                  }),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ChangeNotifierBuilder(
                  notifier: _compassController.showCompass,
                  builder: (context, showCompass) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: showCompass.value
                          ? IconButton.filled(
                              key: const Key('compass-button'),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(Colors.white),
                                elevation: WidgetStateProperty.all(2),
                                shadowColor: WidgetStateProperty.all(Colors.black),
                              ),
                              tooltip: 'Nach Norden orientieren'.i18n,
                              color: Colors.black,
                              onPressed: () {
                                _controller.animateTo(rotation: 0);
                                showCompass.value = false;
                              },
                              icon: ChangeNotifierBuilder(
                                  notifier: _compassController.bearing,
                                  builder: (context, bearing) {
                                    return Transform.rotate(
                                      angle: bearing.value * math.pi / 180.0,
                                      child:
                                          SvgPicture.asset('assets/compass_needle.svg', height: 24),
                                    );
                                  }),
                              padding: const EdgeInsets.all(10),
                            )
                          : const SizedBox(
                              key: Key('compass-placeholder'),
                            ),
                    );
                  }),
            ),
          ),
          ChangeNotifierBuilder(
            notifier: AppSettings.I,
            builder: (context, settings) {
              if (!settings.showOverlay) return const SizedBox();
              return Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: PopupMenuButton(
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: enums.Dimension.PM1_0,
                        child: Text('PM1.0'),
                      ),
                      const PopupMenuItem(
                        value: enums.Dimension.PM2_5,
                        child: Text('PM2.5'),
                      ),
                      const PopupMenuItem(
                        value: enums.Dimension.PM10_0,
                        child: Text('PM10.0'),
                      ),
                      PopupMenuItem(
                        value: enums.Dimension.TEMPERATURE,
                        child: Text('Temperatur'.i18n),
                      ),
                    ],
                    onSelected: (value) async {
                      // Wait for the popup menu closing animation to finish to avoid perception of lag
                      await Future.delayed(const Duration(milliseconds: 330));
                      setState(() {
                        mapDisplayType = value;
                        getIt<PreferencesHandler>().selectedPM = value;
                      });
                    },
                    child: IconButton.filled(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        elevation: WidgetStateProperty.all(2),
                        shadowColor: WidgetStateProperty.all(Colors.black),
                      ),
                      tooltip: 'Angezeigte Feinstaubgröße auswählen'.i18n,
                      color: Colors.black,
                      onPressed: null,
                      icon: SizedBox(
                        height: 44,
                        width: 44,
                        child: Center(
                          child: Text(
                            enums.Dimension.get_name(mapDisplayType),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(0),
                    ),
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: StartButton(page: 'map', updateGPSCallback: () => updateGPS(newZoom: 17)),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: IconButton.filled(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  elevation: WidgetStateProperty.all(2),
                  shadowColor: WidgetStateProperty.all(Colors.black),
                ),
                tooltip: 'Letzte Messdaten'.i18n,
                color: Colors.black,
                onPressed: () {
                  TripController tripController = context.read<TripController>();
                  Trip? trip = tripController.primaryTripToDisplay;
                  if (trip?.data.lastOrNull != null) {
                    showMarkerDialog(trip!.data.last, isInfo: true);
                  } else {
                    Toaster.showFailureToast('Starte eine Messung, um Messwerte anzuzeigen'.i18n);
                  }
                },
                icon: const Icon(Icons.stacked_line_chart),
                padding: const EdgeInsets.all(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getPMColor(double? d) {
    if (d == null) return Colors.black;
    int f = d.floor();
    f *= 10;
    f -= f % 100;
    if (f < 50) {
      f = 50;
    } else if (f > 900) {
      f = 900;
    }
    return Colors.pink[f] ?? Colors.red;
  }
}

extension _RemoveNulls<T extends Object> on List<T?> {
  List<T> removeNulls() => where((element) => element != null).toList().cast<T>();
}

class StationPM {
  final double? pm1, pm25, pm10;

  const StationPM({this.pm1, this.pm25, this.pm10});
}

class CompassController extends ChangeNotifier {
  ValueNotifier<double> bearing = ValueNotifier(0);

  ValueNotifier<bool> showCompass = ValueNotifier(false);
}
