import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/domain/dimensions.dart' as enums;
import 'package:luftdaten.at/core/utils/gradient_color.dart';
import 'package:luftdaten.at/features/map/presentation/pages/map_page.i18n.dart';

/// Colour scale descriptions for the Luftkarte dimension chip menu.
///
/// PM1/PM2.5/PM10 follow the Eu‑AQI µg/m³ hourly bands implemented in [enums.Dimension.getColor].
/// Temperature follows the gradient used for measurement trail markers ([GradientColor.temperature]).
class MapDimensionLegend extends StatelessWidget {
  const MapDimensionLegend({super.key, required this.dimensionId});

  final int dimensionId;

  static String _formatNum(num n) {
    final d = n.toDouble();
    if (d % 1 == 0) {
      return d.toInt().toString();
    }
    return n.toString();
  }

  List<Widget> _euPmRows(BuildContext context) {
    final uppers = enums.Dimension.europeanEuPmInclusiveUpperMicrograms(dimensionId);
    if (uppers == null || uppers.length != 5) {
      return [];
    }
    final colors = enums.Dimension.europeanEuPmBandColors();
    if (colors.length != 6) {
      return [];
    }

    final List<(Color color, String label)> rows = [
      (
        colors[0],
        '≤ %s µg/m³'.i18n.fill([_formatNum(uppers[0])]),
      ),
      for (var i = 1; i < 5; i++)
        (
          colors[i],
          '> %s – ≤ %s µg/m³'.i18n.fill([_formatNum(uppers[i - 1]), _formatNum(uppers[i])]),
        ),
      (
        colors[5],
        '> %s µg/m³'.i18n.fill([_formatNum(uppers[4])]),
      ),
    ];

    return rows.map((e) => _LegendRow(color: e.$1, label: e.$2)).toList(growable: false);
  }

  List<Widget> _temperatureRows() {
    final g = GradientColor.temperature();

    List<(double sampleMid, String label)> temperatureBands = [
      (14.0, '< %s °C'.i18n.fill(['15'])),
      (17.5, '%s °C bis < %s °C'.i18n.fill(['15', '20'])),
      (22.5, '%s °C bis < %s °C'.i18n.fill(['20', '25'])),
      (27.5, '%s °C bis < %s °C'.i18n.fill(['25', '30'])),
      (32.5, '%s °C bis < %s °C'.i18n.fill(['30', '35'])),
      (36.0, '%s °C oder mehr'.i18n.fill(['35'])),
    ];

    return temperatureBands
        .map((e) => _LegendRow(color: g.getColor(e.$1), label: e.$2))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final pmRows = _euPmRows(context);
    if (pmRows.isNotEmpty) {
      return _legendPanel(
        context,
        [
          Text(
            'Farben (Eu‑Luftqualitätsindex für Feinstaub, µg/m³ · stündliche Schwellen)'.i18n,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...pmRows,
          const SizedBox(height: 8),
          Text(
            'Orientiert sich an den Farbstufen der Europäischen Umweltagentur.'.i18n,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ],
      );
    }

    if (dimensionId == enums.Dimension.TEMPERATURE) {
      return _legendPanel(
        context,
        [
          Text(
            'Farben (Temperatur · Messverlauf)'.i18n,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._temperatureRows(),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

Widget _legendPanel(BuildContext context, List<Widget> body) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            tooltip: 'Schließen'.i18n,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        ...body,
      ],
    ),
  );
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
