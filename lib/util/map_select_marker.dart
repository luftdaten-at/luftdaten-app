import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/controller/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/model/ble_device.i18n.dart';

class MapScreen extends StatefulWidget {
  final AirStationConfigWizardController controller;

  // Constructor to accept the controller
  MapScreen({required this.controller});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? selectedPosition;
  double longitude = 0;
  double latitude = 0;
  double height = 0;

  // Controllers for the input fields
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.getCurrentLocation();
    longitude = widget.controller.current_position.longitude;
    latitude = widget.controller.current_position.latitude;

    // Initialize controllers with the initial values
    longitudeController.text = longitude.toString();
    latitudeController.text = latitude.toString();
    heightController.text = height.toString();
  }

  @override
  void dispose() {
    // Dispose of the controllers when not needed
    longitudeController.dispose();
    latitudeController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 300,
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
                      // Update text controllers whenever a marker is set
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
            // Longitude Input Field
            TextFormField(
              controller: longitudeController,
              decoration: InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  longitude = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 16),
            // Latitude Input Field
            TextFormField(
              controller: latitudeController,
              decoration: InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  latitude = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 16),
            // Height Input Field
            TextFormField(
              controller: heightController,
              decoration: InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  height = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 30),
            // Button to proceed to WiFi Configuration
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.controller.config!.longitude = longitude;
                  widget.controller.config!.latitude = latitude;
                  widget.controller.config!.height = height;

                  widget.controller.stage = AirStationConfigWizardStage.configureWifiChoice;
                });
              },
              child: Text('Continue to WiFi Configuration'.i18n),
            ),
          ],
        ),
      ),
    );
  }
}
