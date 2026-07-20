import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_values_preferences.dart';
import 'package:luftdaten.at/features/measurements/logic/uv_index.dart';
import 'package:luftdaten.at/features/measurements/presentation/pages/chart_page.i18n.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/latest_measurement_layout.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_chart_builder.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_sparkline.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_values_config_dialog.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/sensor_data_point_with_timestamp.dart';

class LatestMeasurementPanel extends StatefulWidget {
  const LatestMeasurementPanel({
    super.key,
    required this.latestPoint,
    required this.history,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
  });

  final MeasuredDataPoint latestPoint;
  final List<MeasuredDataPoint> history;
  final List<FlattenedDataPoint> flattenedData;
  final List<List<SensorDataPointWithTimestamp>> reshapedData;
  final Set<LDSensor> tripSensors;
  final ChartSeriesPreferences chartPrefs;

  @override
  State<LatestMeasurementPanel> createState() => _LatestMeasurementPanelState();
}

class _LatestMeasurementPanelState extends State<LatestMeasurementPanel> {
  LatestMeasurementExpansionKey? _expandedKey;

  void _toggleExpansion(LatestMeasurementExpansionKey key) {
    setState(() {
      _expandedKey = _expandedKey == key ? null : key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      notifier: getIt<MeasurementValuesPreferences>(),
      builder: (context, prefs) {
        final allEntries = MeasurementMetricParser.fromDataPoint(widget.latestPoint);
        if (allEntries.isEmpty) return const SizedBox.shrink();

        final visibleEntries = allEntries
            .where(
              (entry) => prefs.isVisible(
                entry.seriesKey,
                tripSensors: widget.tripSensors,
                sensor: entry.sensor,
                quantity: entry.quantity,
              ),
            )
            .toList();
        if (visibleEntries.isEmpty) return const SizedBox.shrink();

        final layout = LatestMeasurementLayout.group(visibleEntries);
        final showBattery = AppSettings.I.showBatteryGraph;
        final batteryData = getIt<BatteryInfoAggregator>().collectedBatteryDetails;
        final latestBattery = batteryData.isNotEmpty ? batteryData.last : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Letzte Messwerte'.i18n,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'Gemessen:'.i18n} ${DateFormat('dd.MM.yyyy, HH:mm.').format(widget.latestPoint.timestamp)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: allEntries.length >= 2
                        ? IconButton(
                            icon: const Icon(Icons.tune),
                            tooltip: 'Messwerte konfigurieren'.i18n,
                            onPressed: () => showMeasurementValuesConfigDialog(
                              context,
                              entries: allEntries,
                              tripSensors: widget.tripSensors,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            if (layout.hasClimatePair)
              _ClimateSquareTilesSection(
                temperature: layout.temperature,
                humidity: layout.humidity,
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
              ),
            if (layout.hasParticulateComposite)
              _ParticulateCompositeSection(
                pm25: layout.pm25,
                pm1: layout.pm1,
                pm10: layout.pm10,
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
              ),
            if (layout.hasUvComposite)
              _UvCompositeSection(
                uva: layout.uva,
                uvb: layout.uvb,
                uvc: layout.uvc,
                firmwareUvi: layout.firmwareUvi,
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                history: widget.history,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
              ),
            if (layout.gridOthers.isNotEmpty || (showBattery && latestBattery != null))
              _TwoColumnGrid(
                entries: layout.gridOthers,
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
                showBattery: showBattery,
                latestBattery: latestBattery,
              ),
          ],
        );
      },
    );
  }
}

class _TwoColumnGrid extends StatelessWidget {
  const _TwoColumnGrid({
    required this.entries,
    required this.expandedKey,
    required this.onToggle,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
    required this.showBattery,
    required this.latestBattery,
  });

  final List<MeasurementMetricEntry> entries;
  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;
  final List<FlattenedDataPoint> flattenedData;
  final List<List<SensorDataPointWithTimestamp>> reshapedData;
  final Set<LDSensor> tripSensors;
  final ChartSeriesPreferences chartPrefs;
  final bool showBattery;
  final BatteryDetails? latestBattery;

  Iterable<LatestMeasurementExpansionKey> get _gridExpansionKeys sync* {
    for (final entry in entries) {
      yield LatestMeasurementLayout.expansionKeyFor(entry);
    }
    if (showBattery && latestBattery != null) {
      yield LatestMeasurementExpansionKey.batteryPercentage;
      yield LatestMeasurementExpansionKey.batteryVoltage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridKeys = _gridExpansionKeys.toSet();
    final cards = <Widget>[
      for (final entry in entries)
        _MetricCardSection(
          entry: entry,
          expansionKey: LatestMeasurementLayout.expansionKeyFor(entry),
          expandedKey: expandedKey,
          onToggle: onToggle,
          flattenedData: flattenedData,
          reshapedData: reshapedData,
          tripSensors: tripSensors,
          chartPrefs: chartPrefs,
          inlineChart: false,
        ),
      if (showBattery && latestBattery != null) ...[
        _BatteryCard(
          title: 'Batteriestatus'.i18n,
          value: '${latestBattery!.percentage?.round() ?? 0} %',
          expansionKey: LatestMeasurementExpansionKey.batteryPercentage,
          expandedKey: expandedKey,
          onToggle: onToggle,
        ),
        _BatteryCard(
          title: 'Batteriespannung'.i18n,
          value: '${latestBattery!.voltage?.toStringAsFixed(1) ?? '-'} V',
          expansionKey: LatestMeasurementExpansionKey.batteryVoltage,
          expandedKey: expandedKey,
          onToggle: onToggle,
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final tileWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: tileWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: card,
                    ),
                  ),
              ],
            );
          },
        ),
        if (expandedKey != null && gridKeys.contains(expandedKey))
          MeasurementChartBuilder.buildExpandedChart(
            expansionKey: expandedKey!,
            flattenedData: flattenedData,
            reshapedData: reshapedData,
            preferences: chartPrefs,
            tripSensors: tripSensors,
          ),
      ],
    );
  }
}

class _MetricCardSection extends StatelessWidget {
  const _MetricCardSection({
    required this.entry,
    required this.expansionKey,
    required this.expandedKey,
    required this.onToggle,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
    this.inlineChart = true,
  });

  final MeasurementMetricEntry entry;
  final LatestMeasurementExpansionKey expansionKey;
  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;
  final List<FlattenedDataPoint> flattenedData;
  final List<List<SensorDataPointWithTimestamp>> reshapedData;
  final Set<LDSensor> tripSensors;
  final ChartSeriesPreferences chartPrefs;
  final bool inlineChart;

  @override
  Widget build(BuildContext context) {
    final isExpanded = expandedKey == expansionKey;
    final sparklinePoints = MeasurementSparklineData.forEntry(
      entry: entry,
      flattenedData: flattenedData,
      reshapedData: reshapedData,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LatestMetricCard(
            entry: entry,
            sparklinePoints: sparklinePoints,
            selected: isExpanded,
            onTap: () => onToggle(expansionKey),
          ),
          if (inlineChart && isExpanded)
            MeasurementChartBuilder.buildExpandedChart(
              expansionKey: expansionKey,
              flattenedData: flattenedData,
              reshapedData: reshapedData,
              preferences: chartPrefs,
              tripSensors: tripSensors,
            ),
        ],
      ),
    );
  }
}

class _ClimateSquareTilesSection extends StatelessWidget {
  const _ClimateSquareTilesSection({
    required this.temperature,
    required this.humidity,
    required this.expandedKey,
    required this.onToggle,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
  });

  final MeasurementMetricEntry? temperature;
  final MeasurementMetricEntry? humidity;
  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;
  final List<FlattenedDataPoint> flattenedData;
  final List<List<SensorDataPointWithTimestamp>> reshapedData;
  final Set<LDSensor> tripSensors;
  final ChartSeriesPreferences chartPrefs;

  @override
  Widget build(BuildContext context) {
    final isExpanded = expandedKey == LatestMeasurementExpansionKey.climate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final tileWidth = (constraints.maxWidth - spacing) / 2;
              return Row(
                children: [
                  if (temperature != null)
                    SizedBox(
                      width: tileWidth,
                      child: _SquareClimateTile(
                        entry: temperature!,
                        sparklinePoints: MeasurementSparklineData.forEntry(
                          entry: temperature!,
                          flattenedData: flattenedData,
                          reshapedData: reshapedData,
                        ),
                        selected: isExpanded,
                        onTap: () => onToggle(LatestMeasurementExpansionKey.climate),
                      ),
                    ),
                  if (temperature != null && humidity != null) const SizedBox(width: spacing),
                  if (humidity != null)
                    SizedBox(
                      width: tileWidth,
                      child: _SquareClimateTile(
                        entry: humidity!,
                        sparklinePoints: MeasurementSparklineData.forEntry(
                          entry: humidity!,
                          flattenedData: flattenedData,
                          reshapedData: reshapedData,
                        ),
                        selected: isExpanded,
                        onTap: () => onToggle(LatestMeasurementExpansionKey.climate),
                      ),
                    ),
                ],
              );
            },
          ),
          if (isExpanded)
            MeasurementChartBuilder.buildExpandedChart(
              expansionKey: LatestMeasurementExpansionKey.climate,
              flattenedData: flattenedData,
              reshapedData: reshapedData,
              preferences: chartPrefs,
              tripSensors: tripSensors,
            ),
        ],
      ),
    );
  }
}

class _SquareClimateTile extends StatelessWidget {
  const _SquareClimateTile({
    required this.entry,
    required this.sparklinePoints,
    required this.selected,
    required this.onTap,
  });

  final MeasurementMetricEntry entry;
  final List<MeasurementSparklinePoint> sparklinePoints;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.unit.isNotEmpty)
                  Text(
                    entry.unit,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                const Spacer(),
                Text(
                  entry.formattedValue,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: entry.statusColor,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return MeasurementSparkline(
                      points: sparklinePoints,
                      color: entry.statusColor,
                      width: constraints.maxWidth,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticulateCompositeSection extends StatelessWidget {
  const _ParticulateCompositeSection({
    required this.pm25,
    required this.pm1,
    required this.pm10,
    required this.expandedKey,
    required this.onToggle,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
  });

  final MeasurementMetricEntry? pm25;
  final MeasurementMetricEntry? pm1;
  final MeasurementMetricEntry? pm10;
  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;
  final List<FlattenedDataPoint> flattenedData;
  final List<List<SensorDataPointWithTimestamp>> reshapedData;
  final Set<LDSensor> tripSensors;
  final ChartSeriesPreferences chartPrefs;

  @override
  Widget build(BuildContext context) {
    final isExpanded = expandedKey == LatestMeasurementExpansionKey.particulate;
    final hero = pm25;
    final sparklinePoints = MeasurementSparklineData.forPm25(flattenedData: flattenedData);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onToggle(LatestMeasurementExpansionKey.particulate),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isExpanded
                      ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                      : null,
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: hero != null
                          ? _MetricValueColumn(entry: hero, heroStyle: true)
                          : Text(
                              'Feinstaub'.i18n,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                    ),
                    if (pm1 != null || pm10 != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pm1 != null) _SmallMetricRow(entry: pm1!),
                            if (pm1 != null && pm10 != null) const SizedBox(height: 8),
                            if (pm10 != null) _SmallMetricRow(entry: pm10!),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    MeasurementSparkline(
                      points: sparklinePoints,
                      color: hero?.statusColor ?? Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            MeasurementChartBuilder.buildExpandedChart(
              expansionKey: LatestMeasurementExpansionKey.particulate,
              flattenedData: flattenedData,
              reshapedData: reshapedData,
              preferences: chartPrefs,
              tripSensors: tripSensors,
            ),
        ],
      ),
    );
  }
}

class _UvCompositeSection extends StatelessWidget {
  const _UvCompositeSection({
    required this.uva,
    required this.uvb,
    required this.uvc,
    required this.firmwareUvi,
    required this.expandedKey,
    required this.onToggle,
    required this.history,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
  });

  final MeasurementMetricEntry? uva;
  final MeasurementMetricEntry? uvb;
  final MeasurementMetricEntry? uvc;
  final MeasurementMetricEntry? firmwareUvi;
  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;
  final List<MeasuredDataPoint> history;
  final List<FlattenedDataPoint> flattenedData;
  final List<List<SensorDataPointWithTimestamp>> reshapedData;
  final Set<LDSensor> tripSensors;
  final ChartSeriesPreferences chartPrefs;

  @override
  Widget build(BuildContext context) {
    final isExpanded = expandedKey == LatestMeasurementExpansionKey.uv;
    final snapshot = UvIndex.heroFromEntries(
      uva: uva,
      uvb: uvb,
      uvc: uvc,
      firmwareUvi: firmwareUvi,
    );
    final sparklinePoints = MeasurementSparklineData.forUvIndex(history: history);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onToggle(LatestMeasurementExpansionKey.uv),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isExpanded
                      ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                      : null,
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UV-Index'.i18n,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            snapshot.heroFormatted,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: snapshot.heroColor,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (snapshot.hasAnyBand) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (snapshot.uva != null) _SmallMetricRow(entry: snapshot.uva!),
                            if (snapshot.uva != null && snapshot.uvb != null)
                              const SizedBox(height: 8),
                            if (snapshot.uvb != null) _SmallMetricRow(entry: snapshot.uvb!),
                            if ((snapshot.uva != null || snapshot.uvb != null) &&
                                snapshot.uvc != null)
                              const SizedBox(height: 8),
                            if (snapshot.uvc != null) _SmallMetricRow(entry: snapshot.uvc!),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    MeasurementSparkline(
                      points: sparklinePoints,
                      color: snapshot.heroColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            MeasurementChartBuilder.buildExpandedChart(
              expansionKey: LatestMeasurementExpansionKey.uv,
              flattenedData: flattenedData,
              reshapedData: reshapedData,
              preferences: chartPrefs,
              tripSensors: tripSensors,
            ),
        ],
      ),
    );
  }
}

class _SmallMetricRow extends StatelessWidget {
  const _SmallMetricRow({required this.entry});

  final MeasurementMetricEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.label,
          style: Theme.of(context).textTheme.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          entry.formattedValue,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: entry.statusColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard({
    required this.title,
    required this.value,
    required this.expansionKey,
    required this.expandedKey,
    required this.onToggle,
  });

  final String title;
  final String value;
  final LatestMeasurementExpansionKey expansionKey;
  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;

  @override
  Widget build(BuildContext context) {
    return _SimpleMetricCard(
      label: title,
      value: value,
      selected: expandedKey == expansionKey,
      onTap: () => onToggle(expansionKey),
    );
  }
}

class _LatestMetricCard extends StatelessWidget {
  const _LatestMetricCard({
    required this.entry,
    required this.sparklinePoints,
    required this.selected,
    required this.onTap,
  });

  final MeasurementMetricEntry entry;
  final List<MeasurementSparklinePoint> sparklinePoints;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: _MetricValueColumn(entry: entry)),
              const SizedBox(width: 8),
              MeasurementSparkline(
                points: sparklinePoints,
                color: entry.statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleMetricCard extends StatelessWidget {
  const _SimpleMetricCard({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricValueColumn extends StatelessWidget {
  const _MetricValueColumn({required this.entry, this.heroStyle = false});

  final MeasurementMetricEntry entry;
  final bool heroStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.label,
          style: Theme.of(context).textTheme.labelMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (entry.unit.isNotEmpty)
          Text(
            entry.unit,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        const SizedBox(height: 4),
        Text(
          entry.formattedValue,
          style: (heroStyle
                  ? Theme.of(context).textTheme.headlineMedium
                  : Theme.of(context).textTheme.headlineMedium)
              ?.copyWith(
                color: entry.statusColor,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
        ),
        if (entry.sensorSymbol.isNotEmpty)
          Text(
            entry.sensorHint,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
