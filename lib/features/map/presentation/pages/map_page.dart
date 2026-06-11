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
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/app/preferences_handler.dart';
import 'package:luftdaten.at/core/app/toaster.dart';
import 'package:luftdaten.at/features/dashboard/logic/favorites_manager.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';
import 'package:luftdaten.at/features/measurements/logic/workshop_controller.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/measurement.dart';
import 'package:luftdaten.at/features/map/presentation/pages/map_page.i18n.dart';
import 'package:luftdaten.at/features/map/presentation/pages/station_details_page.dart';
import 'package:luftdaten.at/core/utils/gradient_color.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/core/widgets/start_button.dart';
import 'package:luftdaten.at/features/map/presentation/widgets/map_collapsible_legend.dart';
import 'package:luftdaten.at/features/map/presentation/widgets/map_dimension_legend.dart';
import 'package:luftdaten.at/features/map/presentation/widgets/marker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:luftdaten.at/features/map/logic/http_provider.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';
import 'package:luftdaten.at/features/measurements/data/value_marker.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:luftdaten.at/core/domain/dimensions.dart' as enums;

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
  double _zoom = 11.2;
  final MarkerDialogController _markerDialogController = MarkerDialogController();

  int stationsLength = 0;
  List<Marker> historyMarkers = [];
  late TextEditingController _textController;
  final TripController router = getIt<TripController>();
  late final WorkshopController _workshopController;
  int primaryItem = 5; // = PM10.0

  bool autoCenter = true;

  int mapDisplayType = enums.Dimension.PM2_5;
  double _legendPanelHeight = 0;

  double _bottomOffsetAboveLegend({double whenNoLegend = 15}) {
    if (!MapDimensionLegendData.hasLegend(mapDisplayType)) {
      return whenNoLegend;
    }
    final inset = _legendPanelHeight > 0
        ? _legendPanelHeight
        : MapCollapsibleLegend.collapsedHeight;
    return inset + 8;
  }

  /// Stable TileLayer to avoid rebuild-driven connection churn (reduces tile load errors).
  /// Use tile.openstreetmap.org without subdomains (OSM recommends this; see operations#737).
  static final TileLayer _osmTileLayer = TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'at.luftdaten.pmble',
  );

  Color getLDColor(MeasuredDataPoint item) {
    if (mapDisplayType == enums.Dimension.PM1_0) {
      if (item.flatten.pm1 == null) return Colors.grey;
      return enums.Dimension.getColor(enums.Dimension.PM1_0, item.flatten.pm1!) as Color;
    } else if (mapDisplayType == enums.Dimension.PM2_5) {
      if (item.flatten.pm25 == null) return Colors.grey;
      return enums.Dimension.getColor(enums.Dimension.PM2_5, item.flatten.pm25!) as Color;
    } else if (mapDisplayType == enums.Dimension.PM10_0) {
      if (item.flatten.pm10 == null) return Colors.grey;
      return enums.Dimension.getColor(enums.Dimension.PM10_0, item.flatten.pm10!) as Color;
    } else if (mapDisplayType == enums.Dimension.TEMPERATURE) {
      if (item.flatten.temperature == null) return Colors.grey;
      return GradientColor.temperature().getColor(item.flatten.temperature!);
    }
    return Colors.blue;
  }

  bool measurementHasDisplayedValue(Measurement m) {
    final v = m.get_valueByDimension(mapDisplayType);
    return v != null && !v.isNaN;
  }

  void updateStations({bool zoomin = false, MapEvent? event}) {
    getIt<MapHttpProvider>().fetch();
  }

  @override
  bool get wantKeepAlive => true;

  bool _tripHasTemperature(Trip? trip) {
    if (trip == null) return false;
    return trip.data.any((point) => point.flatten.temperature != null);
  }

  bool _canSelectTemperatureOnMap() {
    return _workshopController.currentWorkshop != null ||
        _tripHasTemperature(router.primaryTripToDisplay);
  }

  void _normalizeMapDimension() {
    if (!_canSelectTemperatureOnMap() &&
        mapDisplayType == enums.Dimension.TEMPERATURE) {
      mapDisplayType = enums.Dimension.PM2_5;
      getIt<PreferencesHandler>().selectedPM = enums.Dimension.PM2_5;
    }
  }

  void _syncMapDimension() {
    if (!mounted) return;
    setState(() {
      _normalizeMapDimension();
    });
  }

  @override
  void initState() {
    super.initState();
    logger.d("MapPage: initState()");
    _textController = TextEditingController();
    _workshopController = getIt<WorkshopController>();
    _workshopController.addListener(_syncMapDimension);
    router.addListener(_syncMapDimension);
    mapDisplayType = getIt<PreferencesHandler>().selectedPM;
    _normalizeMapDimension();
  }

  @override
  void dispose() {
    _workshopController.removeListener(_syncMapDimension);
    router.removeListener(_syncMapDimension);
    _textController.dispose();
    super.dispose();
  }

  void showStationDialog(Measurement item) {
    SingleStationHttpProvider provider = SingleStationHttpProvider(item.deviceId.toString());
    showLDDialog(
      context,
      title: "Station #%s".i18n.fill([item.deviceId.toString()]),
      trailing: StatefulBuilder(builder: (_, setState) {
        FavoritesManager favoritesManager = getIt<FavoritesManager>();
        bool selected = favoritesManager.hasId(item.deviceId);
        return IconButton(
          tooltip: selected ? 'Aus Favoriten entfernen'.i18n : 'Zu Favoriten hinzufügen'.i18n,
          onPressed: () async {
            if (selected) {
              favoritesManager.removeId(item.deviceId);
              setState(() {});
            } else {
              Favorite favorite =
                  Favorite(id: item.deviceId, latLng: LatLng(item.location.lat, item.location.lon));
              favoritesManager.add(favorite);
              setState(() {});
              await setLocaleIdentifier(locale ?? 'de');
              List<Placemark> placemarks = await placemarkFromCoordinates(
                item.location.lat,
                item.location.lon,
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
              if (!provider.hourly24hReady) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitDualRing(
                      color: Theme.of(context).primaryColor,
                      size: 40,
                      lineWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text("Lade Daten von Server".i18n),
                  ],
                );
              }
              const chartDimension = enums.Dimension.PM2_5;
              final chartData = provider.hourly24h
                  .where((item) {
                    final value = item.valueForDimension(chartDimension);
                    return value != null && !value.isNaN;
                  })
                  .toList();
              if (chartData.isEmpty) {
                return Center(child: Text("Keine Daten verfügbar".i18n));
              }
              return SfCartesianChart(
                primaryXAxis: DateTimeAxis(dateFormat: DateFormat('HH:mm')),
                title: ChartTitle(text: 'Letzte 24 Stunden (Stundenmittel)'.i18n),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Feinstaubbelastung (μg/m³)'.i18n),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<DataItem, DateTime>>[
                  ColumnSeries<DataItem, DateTime>(
                    dataSource: chartData,
                    xValueMapper: (DataItem item, _) => item.timestamp!,
                    yValueMapper: (DataItem item, _) =>
                        item.valueForDimension(chartDimension)!,
                    name: enums.Dimension.get_name(chartDimension),
                    pointColorMapper: (DataItem item, _) =>
                        enums.Dimension.getColor(
                          chartDimension,
                          item.valueForDimension(chartDimension)!,
                        ) as Color,
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
                    id: item.deviceId,
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
    final mapProvider = context.watch<MapHttpProvider>();
    final showMapLoading = mapProvider.isLoading && mapProvider.allItems.isEmpty;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
        mapController: _controller.mapController,
        options: MapOptions(
          initialCenter: const LatLng(48.21919466912646, 16.383482313924404),
          initialZoom: _zoom,
          maxZoom: 18,
        ),
        children: [
          _osmTileLayer,
          ChangeNotifierBuilder(
              notifier: AppSettings.I,
              builder: (context, settings) {
                final bool showMessnetz =
                    settings.showOverlay && mapDisplayType != enums.Dimension.TEMPERATURE;
                if (!showMessnetz) return const SizedBox();
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
                        .where(measurementHasDisplayedValue)
                        .map(
                          (e) => ValueMarker<Measurement>(
                            point: LatLng(e.location.lat, e.location.lon),
                            value: e,
                            width: 40,
                            height: 40,
                            child: IconButton(
                              onPressed: () => showStationDialog(e),
                              iconSize: 40,
                              padding: EdgeInsets.zero,
                              icon: Builder(builder: (context) {
                                double value =
                                    e.get_valueByDimension(mapDisplayType)!;
                                Color color =
                                    enums.Dimension.getColor(mapDisplayType, value) as Color;
                                return Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: color,
                                  ),
                                  child: Center(
                                    child: Text(
                                      value.toStringAsFixed(value <= 99.9 ? 1 : 0),
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
                        Measurement measurement = (marker as ValueMarker).value as Measurement;
                        double? value = measurement.get_valueByDimension(mapDisplayType);
                        if (value != null && !value.isNaN) {
                          acc += value;
                          count++;
                        }
                      }
                      double? value = count == 0 ? null : acc / count;
                      Color color;
                      if (value != null) {
                        color =
                            enums.Dimension.getColor(mapDisplayType, value) as Color;
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
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: _bottomOffsetAboveLegend(whenNoLegend: 20),
              ),
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
          ChangeNotifierBuilder(
            notifier: AppSettings.I,
            builder: (context, settings) {
              return ChangeNotifierBuilder(
                notifier: router,
                builder: (context, _) {
                  final workshopActive = _workshopController.currentWorkshop != null;
                  final trip = router.primaryTripToDisplay;
                  final hasLocalTrail = trip != null && trip.data.isNotEmpty;
                  if (!settings.showOverlay && !workshopActive && !hasLocalTrail) {
                    return const SizedBox();
                  }
                  final canSelectTemperature = _canSelectTemperatureOnMap();
                  return Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: PopupMenuButton<int>(
                        itemBuilder: (context) => [
                          const PopupMenuItem<int>(
                            value: enums.Dimension.PM1_0,
                            child: Text('PM1.0'),
                          ),
                          const PopupMenuItem<int>(
                            value: enums.Dimension.PM2_5,
                            child: Text('PM2.5'),
                          ),
                          const PopupMenuItem<int>(
                            value: enums.Dimension.PM10_0,
                            child: Text('PM10.0'),
                          ),
                          if (canSelectTemperature)
                            PopupMenuItem<int>(
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
                          tooltip: 'Angezeigte Messgröße auswählen'.i18n,
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
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: MapCollapsibleLegend(
                dimensionId: mapDisplayType,
                onHeightChanged: (height) {
                  if (_legendPanelHeight == height) return;
                  setState(() => _legendPanelHeight = height);
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(
                bottom: _bottomOffsetAboveLegend(),
              ),
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
          if (showMapLoading)
            ColoredBox(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitDualRing(
                      color: Theme.of(context).primaryColor,
                      size: 40,
                      lineWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text("Lade Daten von Server".i18n),
                  ],
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
