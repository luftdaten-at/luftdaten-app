import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_factory.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';
import 'package:luftdaten.at/features/measurements/presentation/pages/mock_measurement_data_page.i18n.dart';
import 'package:provider/provider.dart';

class MockMeasurementDataPage extends StatefulWidget {
  const MockMeasurementDataPage({super.key});

  static const String route = 'mock-measurement-data';

  @override
  State<MockMeasurementDataPage> createState() => _MockMeasurementDataPageState();
}

class _MockMeasurementDataPageState extends State<MockMeasurementDataPage> {
  void _addPreset(MockMeasurementPreset preset) {
    final tripController = getIt<TripController>();
    final trip = MockMeasurementFactory.buildPreset(preset);

    if (tripController.ongoingTrips.isNotEmpty ||
        tripController.loadedTrips.isNotEmpty) {
      showLDDialog(
        context,
        content: Text(
          'Neu geladene Messpunkte zur aktuellen Anzeige hinzufügen oder aktuelle Anzeige überschreiben?'
              .i18n,
          textAlign: TextAlign.center,
        ),
        title: 'Daten hinzufügen'.i18n,
        icon: Icons.import_export,
        actions: [
          LDDialogAction(
            label: 'Überschreiben'.i18n,
            onTap: () {
              tripController
                ..loadedTrips = []
                ..ongoingTrips = {}
                ..isOngoing = false
                ..currentTripStartedAt = null
                ..addMockLoadedTrip(trip);
              _showAddedToast();
            },
            filled: false,
          ),
          LDDialogAction(
            label: 'Hinzufügen'.i18n,
            onTap: () {
              tripController.addMockLoadedTrip(trip);
              _showAddedToast();
            },
            filled: true,
          ),
        ],
      );
      return;
    }

    tripController.addMockLoadedTrip(trip);
    _showAddedToast();
  }

  void _showAddedToast() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mock-Pfad hinzugefügt.'.i18n)),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Mock-Messdaten'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
      ),
      body: Consumer<TripController>(
        builder: (context, tripController, _) {
          final liveTrip = tripController.isMockLiveActive
              ? tripController.ongoingTrips.values.firstOrNull
              : null;
          final livePointCount = liveTrip?.data.length ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Nur Debug-Build. Fügt Test-Messungen für Karte und Messwerte hinzu.'.i18n,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Voreinstellungen (GPS-Pfad)'.i18n,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _presetButton(
                title: 'Gute Luft'.i18n,
                description: 'Niedrige PM-Werte entlang eines kurzen Wegs.'.i18n,
                onPressed: kDebugMode
                    ? () => _addPreset(MockMeasurementPreset.goodAir)
                    : null,
              ),
              const SizedBox(height: 8),
              _presetButton(
                title: 'Schlechte Luft'.i18n,
                description:
                    'Hohe PM-Werte zum Testen von Warnungen und Legende.'.i18n,
                onPressed: kDebugMode
                    ? () => _addPreset(MockMeasurementPreset.badAir)
                    : null,
              ),
              const SizedBox(height: 8),
              _presetButton(
                title: 'Farbverlauf (Karte)'.i18n,
                description:
                    'PM steigt von gut nach schlecht — ideal für die Farblegende.'.i18n,
                onPressed: kDebugMode
                    ? () => _addPreset(MockMeasurementPreset.mapGradient)
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Live-Mock-Messung'.i18n,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text('Fügt alle 10 Sekunden synthetische Messpunkte hinzu.'.i18n),
              const SizedBox(height: 8),
              if (tripController.isMockLiveActive)
                FilledButton.tonal(
                  onPressed: kDebugMode
                      ? () {
                          tripController.stopMockLiveMeasurement();
                          setState(() {});
                        }
                      : null,
                  child: Text('Live-Mock-Messung stoppen'.i18n),
                )
              else
                FilledButton(
                  onPressed: kDebugMode && !tripController.isOngoing
                      ? () {
                          tripController.startMockLiveMeasurement();
                          setState(() {});
                        }
                      : null,
                  child: Text('Live-Mock-Messung starten'.i18n),
                ),
              if (tripController.isOngoing && !tripController.isMockLiveActive)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Eine echte Messung läuft bereits.'.i18n,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Status'.i18n,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Geladene Mock-Pfade: %s'.i18n.fill([
                  tripController.mockLoadedTripCount.toString(),
                ]),
              ),
              Text(
                tripController.isMockLiveActive
                    ? 'Live-Mock aktiv (%s Punkte)'
                        .i18n
                        .fill([livePointCount.toString()])
                    : 'Live-Mock inaktiv'.i18n,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: kDebugMode && tripController.hasMockTrips
                    ? () {
                        tripController.clearMockTrips();
                        setState(() {});
                      }
                    : null,
                child: Text('Mock-Messdaten entfernen'.i18n),
              ),
              const SizedBox(height: 4),
              Text(
                'Entfernt geladene Mock-Pfade und stoppt die Live-Mock-Messung.'.i18n,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _presetButton({
    required String title,
    required String description,
    required VoidCallback? onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonal(
          onPressed: onPressed,
          child: Text(title),
        ),
        const SizedBox(height: 4),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
