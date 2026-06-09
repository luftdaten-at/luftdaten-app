import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/chart_series_config_dialog.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/chart_series_config_dialog.i18n.dart';

class CenteredChartHeadline extends StatelessWidget {
  const CenteredChartHeadline({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  static const _sideSlotWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          const SizedBox(width: _sideSlotWidth),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(
            width: _sideSlotWidth,
            child: trailing,
          ),
        ],
      ),
    );
  }
}

class ChartSection extends StatelessWidget {
  const ChartSection({
    super.key,
    required this.title,
    required this.chartId,
    required this.seriesOptions,
    required this.chart,
  });

  final String title;
  final ChartSeriesChartId chartId;
  final List<ChartSeriesOption> seriesOptions;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CenteredChartHeadline(
          title: title,
          trailing: seriesOptions.length >= 2
              ? IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Diagramm konfigurieren'.i18n,
                  onPressed: () => showChartSeriesConfigDialog(
                    context,
                    chartTitle: title,
                    chartId: chartId,
                    options: seriesOptions,
                  ),
                )
              : null,
        ),
        chart,
      ],
    );
  }
}
