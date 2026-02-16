import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/features/devices/logic/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.i18n.dart';

class MapScreen extends StatefulWidget {
  final AirStationConfigWizardController controller;

  MapScreen({required this.controller});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? selectedPosition;
  double longitude = 0;
  double latitude = 0;
  double height = 0;

  // Controller für die Eingabefelder
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.getCurrentLocation();
    longitude = widget.controller.current_position.longitude;
    latitude = widget.controller.current_position.latitude;

    // Initialisiere die Controller mit den Anfangswerten
    longitudeController.text = longitude.toString();
    latitudeController.text = latitude.toString();
    heightController.text = height.toString();
  }

  @override
  void dispose() {
    // Dispose der Controller, wenn sie nicht mehr benötigt werden
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
                    IgnorePointer(child: CurrentLocationLayer()),
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
                    height = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 30),
              // Weiter-Button
              FilledButton(
                onPressed: () {
                  setState(() {
                    widget.controller.config!.longitude = longitude;
                    widget.controller.config!.latitude = latitude;
                    widget.controller.config!.height = height;

                    widget.controller.stage = AirStationConfigWizardStage.configureWifiChoice;
                  });
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
