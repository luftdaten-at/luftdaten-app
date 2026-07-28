import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_values_preferences.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/latest_measurement_layout.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_values_config_dialog.i18n.dart';

String measurementTileLabel(MeasurementTileId tile) {
  return switch (tile) {
    MeasurementTileId.particulate => 'Feinstaub'.i18n,
    MeasurementTileId.climate => 'Klima'.i18n,
    MeasurementTileId.uv => 'UV-Bestrahlung'.i18n,
    MeasurementTileId.light => 'Licht'.i18n,
    MeasurementTileId.environment => 'Umgebung'.i18n,
    MeasurementTileId.thermal => 'UTCI / Behaglichkeit'.i18n,
    MeasurementTileId.others => 'Gase & Indizes'.i18n,
  };
}

Future<void> showMeasurementTileConfigDialog(
  BuildContext context, {
  required List<MeasurementTileId> availableTiles,
}) async {
  final prefs = getIt<MeasurementValuesPreferences>();
  final local = {
    for (final tile in availableTiles) tile: prefs.isTileVisible(tile),
  };

  await showLDDialog(
    context,
    title: 'Messwerte konfigurieren'.i18n,
    icon: Icons.tune,
    content: StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Anzuzeigende Kacheln'.i18n),
              const SizedBox(height: 4),
              for (final tile in availableTiles)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: local[tile] ?? true,
                  title: Text(measurementTileLabel(tile)),
                  onChanged: (value) {
                    if (value == null) return;
                    final visibleCount = local.values.where((e) => e).length;
                    if (!value && visibleCount <= 1) {
                      snackMessage(
                        context,
                        'Mindestens eine Kachel muss sichtbar bleiben.'.i18n,
                      );
                      return;
                    }
                    setState(() => local[tile] = value);
                  },
                ),
            ],
          ),
        );
      },
    ),
    actions: [
      LDDialogAction.cancel(),
      LDDialogAction.save(
        onTap: () => prefs.setAllTiles(local),
      ),
    ],
  );
}

Future<void> showMeasurementValuesConfigDialog(
  BuildContext context, {
  required List<MeasurementMetricEntry> entries,
  required Set<LDSensor> tripSensors,
}) async {
  final prefs = getIt<MeasurementValuesPreferences>();
  final local = {
    for (final entry in entries)
      entry.seriesKey: prefs.isVisible(
        entry.seriesKey,
        tripSensors: tripSensors,
        sensor: entry.sensor,
        quantity: entry.quantity,
      ),
  };

  await showLDDialog(
    context,
    title: 'Messwerte konfigurieren'.i18n,
    icon: Icons.tune,
    content: StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Anzuzeigende Daten'.i18n),
              const SizedBox(height: 4),
              for (final entry in entries)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: local[entry.seriesKey] ?? true,
                  title: Text(entry.configLabel),
                  onChanged: (value) {
                    if (value == null) return;
                    final visibleCount = local.values.where((e) => e).length;
                    if (!value && visibleCount <= 1) {
                      snackMessage(
                        context,
                        'Mindestens ein Wert muss sichtbar bleiben.'.i18n,
                      );
                      return;
                    }
                    setState(() => local[entry.seriesKey] = value);
                  },
                ),
            ],
          ),
        );
      },
    ),
    actions: [
      LDDialogAction.cancel(),
      LDDialogAction.save(
        onTap: () => prefs.setAll(local),
      ),
    ],
  );
}
