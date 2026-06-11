import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_values_mock.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_values_panel.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_values_panel.i18n.dart';

/// Debug-only side-by-side preview of all last-measurement box layouts.
class MeasurementValuesComparison extends StatelessWidget {
  const MeasurementValuesComparison({
    super.key,
    this.point,
  });

  final MeasuredDataPoint? point;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final sample = point ?? MeasurementValuesMock.samplePoint();
    final tripSensors = sample.sensorData.map((s) => s.sensor).toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Layout-Vergleich (Debug)'.i18n,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Alle Varianten mit denselben Mock-Messwerten zum Vergleich.'.i18n,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final layout in MeasurementValuesLayout.values) ...[
                Text(
                  layout.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                MeasurementValuesPanel(
                  point: sample,
                  tripSensors: tripSensors,
                  layout: layout,
                  showTimestamp: layout == MeasurementValuesLayout.values.first,
                  showConfigButton: false,
                ),
                if (layout != MeasurementValuesLayout.values.last) ...[
                  const SizedBox(height: 16),
                  Divider(color: Theme.of(context).dividerColor),
                  const SizedBox(height: 16),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
