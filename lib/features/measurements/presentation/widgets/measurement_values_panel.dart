import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_values_panel.i18n.dart';

enum MeasurementValuesLayout {
  md3StatCards,
  appNativeTiles,
  colorFilledKpi,
  groupedSections,
}

extension MeasurementValuesLayoutLabels on MeasurementValuesLayout {
  String get label => switch (this) {
        MeasurementValuesLayout.md3StatCards => 'MD3 Stat Cards'.i18n,
        MeasurementValuesLayout.appNativeTiles => 'App-native Tiles'.i18n,
        MeasurementValuesLayout.colorFilledKpi => 'Color-filled KPI'.i18n,
        MeasurementValuesLayout.groupedSections => 'Gruppierte Sektionen'.i18n,
      };
}

class MeasurementValuesPanel extends StatelessWidget {
  const MeasurementValuesPanel({
    super.key,
    required this.point,
    required this.layout,
    this.showTimestamp = true,
    this.compact = false,
    this.columns,
  });

  final MeasuredDataPoint point;
  final MeasurementValuesLayout layout;
  final bool showTimestamp;
  final bool compact;
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final entries = MeasurementMetricParser.fromDataPoint(point);
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${'Gemessen:'.i18n} ${DateFormat('dd.MM.yyyy, HH:mm.').format(point.timestamp)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        switch (layout) {
          MeasurementValuesLayout.md3StatCards => _MetricGrid(
              entries: entries,
              tileBuilder: (entry) => _Md3StatCard(entry, compact: compact),
              columns: columns,
              compact: compact,
            ),
          MeasurementValuesLayout.appNativeTiles => _MetricGrid(
              entries: entries,
              tileBuilder: (entry) => _AppNativeTile(entry, compact: compact),
              columns: columns,
              compact: compact,
            ),
          MeasurementValuesLayout.colorFilledKpi => _MetricGrid(
              entries: entries,
              tileBuilder: (entry) => _ColorFilledKpi(entry, compact: compact),
              columns: columns,
              compact: compact,
            ),
          MeasurementValuesLayout.groupedSections => _GroupedSections(
              entries: entries,
              compact: compact,
              columns: columns,
            ),
        },
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.entries,
    required this.tileBuilder,
    this.columns,
    this.compact = false,
  });

  final List<MeasurementMetricEntry> entries;
  final Widget Function(MeasurementMetricEntry entry) tileBuilder;
  final int? columns;
  final bool compact;

  static int _columnCount(double width, int? columns, bool compact) {
    if (columns != null) return columns;
    if (compact) return width >= 280 ? 4 : 2;
    return width >= 520 ? 3 : 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = compact ? 6.0 : 8.0;
        final cols = _columnCount(constraints.maxWidth, columns, compact);
        final tileWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final entry in entries)
              SizedBox(
                width: tileWidth,
                child: tileBuilder(entry),
              ),
          ],
        );
      },
    );
  }
}

class _Md3StatCard extends StatelessWidget {
  const _Md3StatCard(this.entry, {this.compact = false});

  final MeasurementMetricEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border(
          left: BorderSide(color: entry.statusColor, width: compact ? 3 : 4),
          top: BorderSide(color: scheme.outlineVariant),
          right: BorderSide(color: scheme.outlineVariant),
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      padding: EdgeInsets.fromLTRB(compact ? 6 : 10, compact ? 6 : 10, compact ? 6 : 10, compact ? 8 : 12),
      child: _MetricTileContent(
        entry: entry,
        valueColor: entry.statusColor,
        compact: compact,
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: compact ? 10 : null,
            ),
      ),
    );
  }
}

class _AppNativeTile extends StatelessWidget {
  const _AppNativeTile(this.entry, {this.compact = false});

  final MeasurementMetricEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      padding: EdgeInsets.all(compact ? 6 : 10),
      child: _MetricTileContent(
        entry: entry,
        valueColor: entry.statusColor,
        compact: compact,
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: compact ? 10 : null,
            ),
      ),
    );
  }
}

class _ColorFilledKpi extends StatelessWidget {
  const _ColorFilledKpi(this.entry, {this.compact = false});

  final MeasurementMetricEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final onColor =
        entry.statusColor.computeLuminance() > 0.179 ? Colors.black : Colors.white;
    final mutedOnColor = onColor.withValues(alpha: 0.85);
    return Container(
      decoration: BoxDecoration(
        color: entry.statusColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      padding: EdgeInsets.all(compact ? 6 : 10),
      child: _MetricTileContent(
        entry: entry,
        valueColor: onColor,
        compact: compact,
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: mutedOnColor,
              fontSize: compact ? 10 : null,
            ),
        unitColor: mutedOnColor,
        sensorColor: mutedOnColor,
      ),
    );
  }
}

class _GroupedSections extends StatelessWidget {
  const _GroupedSections({
    required this.entries,
    this.compact = false,
    this.columns,
  });

  final List<MeasurementMetricEntry> entries;
  final bool compact;
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final grouped = {
      for (final category in MeasurementValueCategory.values)
        category: entries.where((e) => e.category == category).toList(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in MeasurementValueCategory.values)
          if (grouped[category]!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                _categoryLabel(category),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            _MetricGrid(
              entries: grouped[category]!,
              tileBuilder: (entry) => _Md3StatCard(entry, compact: compact),
              columns: columns,
              compact: compact,
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  String _categoryLabel(MeasurementValueCategory category) => switch (category) {
        MeasurementValueCategory.particulate => 'Feinstaub'.i18n,
        MeasurementValueCategory.climate => 'Klima'.i18n,
        MeasurementValueCategory.gases => 'Gase & Indizes'.i18n,
      };
}

class _MetricTileContent extends StatelessWidget {
  const _MetricTileContent({
    required this.entry,
    required this.valueColor,
    this.labelStyle,
    this.unitColor,
    this.sensorColor,
    this.compact = false,
  });

  final MeasurementMetricEntry entry;
  final Color valueColor;
  final TextStyle? labelStyle;
  final Color? unitColor;
  final Color? sensorColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final unitStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
            color: unitColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 9,
            height: 1.1,
          );
      final sensorStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
            color: sensorColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 8,
            height: 1.1,
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  entry.formattedValue,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.1,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(entry.unit, style: unitStyle),
              ],
            ],
          ),
          if (entry.sensorSymbol.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(entry.sensorHint, style: sensorStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      );
    }

    final unitStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: unitColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final sensorStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: sensorColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.label, style: labelStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (entry.unit.isNotEmpty) Text(entry.unit, style: unitStyle),
        const SizedBox(height: 6),
        Text(
          entry.formattedValue,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
        ),
        if (entry.sensorSymbol.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(entry.sensorHint, style: sensorStyle),
          ),
      ],
    );
  }
}
