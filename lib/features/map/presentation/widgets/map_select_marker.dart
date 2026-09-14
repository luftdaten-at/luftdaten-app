import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:luftdaten.at/features/map/logic/device_heading_stream.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/features/devices/logic/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.i18n.dart';

class MapScreen extends StatefulWidget {
  final AirStationConfigWizardController controller;

  const MapScreen({super.key, required this.controller});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  LatLng? selectedPosition;
  double longitude = 0;
  double latitude = 0;
  double height = 0;
  bool _heightEditedByUser = false;

  // Controller für die Eingabefelder
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    final cfg = widget.controller.config;
    if (cfg != null &&
        AirStationConfigWizardController.isValidGeoCoordinate(
          cfg.latitude ?? 0,
          cfg.longitude ?? 0,
        )) {
      if (cfg.height != null) {
        height = cfg.height!;
        _heightEditedByUser = true;
        heightController.text = height.toString();
      }
      _applyCoordinates(cfg.latitude!, cfg.longitude!, markSelected: true);
      return;
    }

    final existing = widget.controller.currentPosition;
    if (AirStationConfigWizardController.isValidGeoCoordinate(
      existing.latitude,
      existing.longitude,
    )) {
      _applyCoordinates(
        existing.latitude,
        existing.longitude,
        altitude: existing.altitude,
        markSelected: true,
        fromGps: true,
      );
      return;
    }

    await widget.controller.getCurrentLocation();
    if (!mounted) return;

    final pos = widget.controller.currentPosition;
    if (AirStationConfigWizardController.isValidGeoCoordinate(
      pos.latitude,
      pos.longitude,
    )) {
      _applyCoordinates(
        pos.latitude,
        pos.longitude,
        altitude: pos.altitude,
        markSelected: true,
        fromGps: true,
      );
    }
  }

  void _applyCoordinates(
    double lat,
    double lon, {
    double? altitude,
    bool markSelected = false,
    bool fromGps = false,
  }) {
    setState(() {
      latitude = lat;
      longitude = lon;
      if (markSelected) {
        selectedPosition = LatLng(lat, lon);
      }
      longitudeController.text = lon.toString();
      latitudeController.text = lat.toString();
      if (!_heightEditedByUser &&
          altitude != null &&
          altitude.isFinite &&
          (fromGps || height == 0)) {
        height = altitude;
        heightController.text = height.toString();
      }
    });
    _mapController.move(LatLng(lat, lon), 14);
  }

  @override
  void dispose() {
    _mapController.dispose();
    longitudeController.dispose();
    latitudeController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Geolokalisierungseinrichtung'),
        centerTitle: true, // Titel zentrieren
        automaticallyImplyLeading: false, // Entferne die Zurück-Taste
      ),
      body: SingleChildScrollView( // Scrollen aktivieren
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Standort-Icon (reduzierte Größe)
              Center(
                child: Icon(
                  Icons.location_on,
                  size: 60, // Reduzierte Größe
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              // Bildschirmtitel
              Text(
                'Geolokalisierung festlegen'.i18n,
                style: const TextStyle(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Kartencontainer
              SizedBox(
                height: 250,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: 10.0,
                    maxZoom: 18,
                    onTap: (tapPosition, point) {
                      setState(() {
                        selectedPosition = point;
                        longitude = point.longitude;
                        latitude = point.latitude;
                        // Aktualisiere die Text-Controller, wann immer ein Marker gesetzt wird
                        longitudeController.text = longitude.toString();
                        latitudeController.text = latitude.toString();
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.pmble.app',
                    ),
                    IgnorePointer(
                      child: CurrentLocationLayer(
                        headingStream: deviceHeadingStream(),
                      ),
                    ),
                    if (selectedPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedPosition!,
                            width: 80,
                            height: 80,
                            child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Eingabefeld für Länge
              TextFormField(
                controller: longitudeController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Längengrad'.i18n,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    longitude = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Eingabefeld für Breite
              TextFormField(
                controller: latitudeController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Breitengrad'.i18n,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    latitude = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Eingabefeld für Höhe
              TextFormField(
                controller: heightController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Höhe (m)'.i18n, // Einheit in Metern
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _heightEditedByUser = true;
                    height = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 30),
              // Weiter-Button
              FilledButton(
                onPressed: () {
                  if (!AirStationConfigWizardController.isValidGeoCoordinate(
                    latitude,
                    longitude,
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bitte einen gültigen Standort festlegen (GPS oder Karte).'
                              .i18n,
                        ),
                      ),
                    );
                    return;
                  }
                  widget.controller.confirmLocationFromWizard(
                    longitude: longitude,
                    latitude: latitude,
                    height: height,
                  );
                },
                child: Text('Weiter zur WLAN-Konfiguration'.i18n),
              ),
              const SizedBox(height: 20), // Zusätzlicher Abstand nach unten
            ],
          ),
        ),
      ),
    );
  }
}
