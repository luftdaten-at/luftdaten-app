import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_values_preferences.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_values_config_dialog.i18n.dart';

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
