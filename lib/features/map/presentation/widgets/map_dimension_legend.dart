import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/domain/dimensions.dart' as enums;
import 'package:luftdaten.at/core/utils/gradient_color.dart';
import 'package:luftdaten.at/features/map/presentation/pages/map_page.i18n.dart';

/// Shared colour-band data for the Luftkarte legend (collapsed strip + expanded rows).
///
/// PM1/PM2.5/PM10 follow the Eu‑AQI µg/m³ hourly bands implemented in [enums.Dimension.getColor].
/// Temperature follows the gradient used for measurement trail markers ([GradientColor.temperature]).
class MapDimensionLegendData {
  MapDimensionLegendData._();

  static String formatNum(num n) {
    final d = n.toDouble();
    if (d % 1 == 0) {
      return d.toInt().toString();
    }
    return n.toString();
  }

  static bool hasLegend(int dimensionId) {
    if (dimensionId == enums.Dimension.TEMPERATURE) {
      return true;
    }
    final uppers = enums.Dimension.europeanEuPmInclusiveUpperMicrograms(dimensionId);
    return uppers != null && uppers.length == 5;
  }

  static List<Color> bandColors(int dimensionId) {
    if (_hasPmLegend(dimensionId)) {
      return enums.Dimension.europeanEuPmBandColors();
    }
    if (dimensionId == enums.Dimension.TEMPERATURE) {
      final g = GradientColor.temperature();
      return [
        for (final sample in [14.0, 17.5, 22.5, 27.5, 32.5, 36.0]) g.getColor(sample),
      ];
    }
    return const [];
  }

  static bool _hasPmLegend(int dimensionId) {
    final uppers = enums.Dimension.europeanEuPmInclusiveUpperMicrograms(dimensionId);
    return uppers != null && uppers.length == 5;
  }

  static List<(Color color, String label)> pmBandLabels(
    BuildContext context,
    int dimensionId,
  ) {
    final uppers = enums.Dimension.europeanEuPmInclusiveUpperMicrograms(dimensionId);
    if (uppers == null || uppers.length != 5) {
      return [];
    }
    final colors = enums.Dimension.europeanEuPmBandColors();
    if (colors.length != 6) {
      return [];
    }

    return [
      (
        colors[0],
        '≤ %s µg/m³'.i18n.fill([formatNum(uppers[0])]),
      ),
      for (var i = 1; i < 5; i++)
        (
          colors[i],
          '> %s – ≤ %s µg/m³'
              .i18n
              .fill([formatNum(uppers[i - 1]), formatNum(uppers[i])]),
        ),
      (
        colors[5],
        '> %s µg/m³'.i18n.fill([formatNum(uppers[4])]),
      ),
    ];
  }

  static List<(Color color, String label)> temperatureBandLabels() {
    final g = GradientColor.temperature();
    final bands = <(double sampleMid, String label)>[
      (14.0, '< %s °C'.i18n.fill(['15'])),
      (17.5, '%s °C bis < %s °C'.i18n.fill(['15', '20'])),
      (22.5, '%s °C bis < %s °C'.i18n.fill(['20', '25'])),
      (27.5, '%s °C bis < %s °C'.i18n.fill(['25', '30'])),
      (32.5, '%s °C bis < %s °C'.i18n.fill(['30', '35'])),
      (36.0, '%s °C oder mehr'.i18n.fill(['35'])),
    ];
    return [
      for (final band in bands) (g.getColor(band.$1), band.$2),
    ];
  }
}

/// Horizontal full-width colour strip for the collapsed map legend.
class MapDimensionLegendStrip extends StatelessWidget {
  const MapDimensionLegendStrip({
    super.key,
    required this.dimensionId,
    this.height = 20,
    this.expanded = false,
  });

  final int dimensionId;
  final double height;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = MapDimensionLegendData.bandColors(dimensionId);
    if (colors.isEmpty) {
      return const SizedBox.shrink();
    }

    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: Row(
            children: [
              for (final color in colors)
                Expanded(
                  child: Container(
                    key: const Key('map-legend-color-segment'),
                    color: color,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
          child: Row(
            children: [
              Text('Gut'.i18n, style: labelStyle),
              Expanded(
                child: Center(
                  child: Icon(
                    expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text('Schlecht'.i18n, style: labelStyle),
            ],
          ),
        ),
      ],
    );
  }
}

/// Expanded legend body (title, labelled rows, footnote).
class MapDimensionLegendContent extends StatelessWidget {
  const MapDimensionLegendContent({super.key, required this.dimensionId});

  final int dimensionId;

  @override
  Widget build(BuildContext context) {
    final pmLabels = MapDimensionLegendData.pmBandLabels(context, dimensionId);
    if (pmLabels.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Farben (Eu‑Luftqualitätsindex für Feinstaub, µg/m³ · stündliche Schwellen)'
                  .i18n,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final row in pmLabels) _LegendRow(color: row.$1, label: row.$2),
            const SizedBox(height: 8),
            Text(
              'Orientiert sich an den Farbstufen der Europäischen Umweltagentur.'.i18n,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      );
    }

    if (dimensionId == enums.Dimension.TEMPERATURE) {
      final tempLabels = MapDimensionLegendData.temperatureBandLabels();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Farben (Temperatur · Messverlauf)'.i18n,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final row in tempLabels) _LegendRow(color: row.$1, label: row.$2),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Backwards-compatible wrapper around [MapDimensionLegendContent].
class MapDimensionLegend extends StatelessWidget {
  const MapDimensionLegend({super.key, required this.dimensionId});

  final int dimensionId;

  @override
  Widget build(BuildContext context) {
    return MapDimensionLegendContent(dimensionId: dimensionId);
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
