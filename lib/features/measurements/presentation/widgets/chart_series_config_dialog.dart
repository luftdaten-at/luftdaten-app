import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/chart_series_config_dialog.i18n.dart';

Future<void> showChartSeriesConfigDialog(
  BuildContext context, {
  required String chartTitle,
  required ChartSeriesChartId chartId,
  required List<ChartSeriesOption> options,
}) async {
  final prefs = getIt<ChartSeriesPreferences>();
  final local = {
    for (final option in options) option.key: prefs.isVisible(chartId, option.key),
  };

  await showLDDialog(
    context,
    title: 'Diagramm konfigurieren'.i18n,
    icon: Icons.tune,
    content: StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chartTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Anzuzeigende Daten'.i18n),
              const SizedBox(height: 4),
              for (final option in options)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: local[option.key] ?? true,
                  title: Text(option.label),
                  onChanged: (value) {
                    if (value == null) return;
                    final visibleCount = local.values.where((e) => e).length;
                    if (!value && visibleCount <= 1) {
                      snackMessage(
                        context,
                        'Mindestens eine Reihe muss sichtbar bleiben.'.i18n,
                      );
                      return;
                    }
                    setState(() => local[option.key] = value);
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
        onTap: () => prefs.setAll(chartId, local),
      ),
    ],
  );
}
