import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';
import 'package:luftdaten.at/features/measurements/logic/environment_context.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_values_preferences.dart';
import 'package:luftdaten.at/features/measurements/logic/light_metrics.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_bands.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_comfort_tracker.dart';
import 'package:luftdaten.at/features/measurements/logic/uv_index.dart';
import 'package:luftdaten.at/features/measurements/presentation/pages/chart_page.i18n.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/latest_measurement_layout.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_chart_builder.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_metric_entry.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_sparkline.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/sensor_data_point_with_timestamp.dart';

const _kTileHeight = 120.0;

String formatMetricValueWithUnit(MeasurementMetricEntry entry) {
  if (entry.unit.isEmpty) return entry.formattedValue;
  return '${entry.formattedValue} ${entry.unit}';
}

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

        final layout = LatestMeasurementLayout.group(allEntries);
        final showBattery = AppSettings.I.showBatteryGraph;
        final batteryData = getIt<BatteryInfoAggregator>().collectedBatteryDetails;
        final latestBattery = batteryData.isNotEmpty ? batteryData.last : null;
        final tileVisible = prefs.isTileVisible;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (layout.hasParticulateComposite &&
                tileVisible(MeasurementTileId.particulate))
              _ParticulateCompositeSection(
                pm25: layout.pm25,
                pm1: layout.pm1,
                pm10: layout.pm10,
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                history: widget.history,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
              ),
            if (layout.hasClimatePair && tileVisible(MeasurementTileId.climate))
              _ClimateTilesSection(
                temperature: layout.temperature,
                humidity: layout.humidity,
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                history: widget.history,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
              ),
            if (layout.hasUvComposite && tileVisible(MeasurementTileId.uv))
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
            if (layout.hasLightComposite && tileVisible(MeasurementTileId.light))
              _LightCompositeSection(
                lux: layout.lux,
                visible: layout.visibleLight,
                infrared: layout.infrared,
                fullSpectrum: layout.fullSpectrum,
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                history: widget.history,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
              ),
            if (layout.hasEnvironmentContext &&
                tileVisible(MeasurementTileId.environment))
              _EnvironmentContextSection(
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                history: widget.history,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
              ),
            if (layout.hasThermalComfort && tileVisible(MeasurementTileId.thermal))
              _ThermalComfortSection(
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                history: widget.history,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
              ),
            if ((layout.gridOthers.isNotEmpty || (showBattery && latestBattery != null)) &&
                tileVisible(MeasurementTileId.others))
              _TwoColumnGrid(
                entries: layout.gridOthers,
                expandedKey: _expandedKey,
                onToggle: _toggleExpansion,
                history: widget.history,
                flattenedData: widget.flattenedData,
                reshapedData: widget.reshapedData,
                tripSensors: widget.tripSensors,
                chartPrefs: widget.chartPrefs,
                showBattery: showBattery,
                latestBattery: latestBattery,
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
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
          ],
        );
      },
    );
  }
}

class _TileShell extends StatelessWidget {
  const _TileShell({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kTileHeight,
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
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TwoColumnGrid extends StatelessWidget {
  const _TwoColumnGrid({
    required this.entries,
    required this.expandedKey,
    required this.onToggle,
    required this.history,
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
  final List<MeasuredDataPoint> history;
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
          history: history,
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
                    height: _kTileHeight,
                    child: card,
                  ),
              ],
            );
          },
        ),
        if (expandedKey != null && gridKeys.contains(expandedKey))
          MeasurementChartBuilder.buildExpandedChart(
            expansionKey: expandedKey!,
            history: history,
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
    required this.history,
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
  final List<MeasuredDataPoint> history;
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

    return Column(
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
            history: history,
            flattenedData: flattenedData,
            reshapedData: reshapedData,
            preferences: chartPrefs,
            tripSensors: tripSensors,
          ),
      ],
    );
  }
}

class _ClimateTilesSection extends StatelessWidget {
  const _ClimateTilesSection({
    required this.temperature,
    required this.humidity,
    required this.expandedKey,
    required this.onToggle,
    required this.history,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
  });

  final MeasurementMetricEntry? temperature;
  final MeasurementMetricEntry? humidity;
  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;
  final List<MeasuredDataPoint> history;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (temperature != null)
                    SizedBox(
                      width: tileWidth,
                      height: _kTileHeight,
                      child: _ClimateTile(
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
                      height: _kTileHeight,
                      child: _ClimateTile(
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
              history: history,
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

class _ClimateTile extends StatelessWidget {
  const _ClimateTile({
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
    return _TileShell(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: Theme.of(context).textTheme.labelMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            formatMetricValueWithUnit(entry),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: entry.statusColor,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              return MeasurementSparkline(
                points: sparklinePoints,
                color: entry.statusColor,
                width: constraints.maxWidth,
                height: 32,
              );
            },
          ),
        ],
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
    required this.history,
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
  final List<MeasuredDataPoint> history;
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
          _TileShell(
            selected: isExpanded,
            onTap: () => onToggle(LatestMeasurementExpansionKey.particulate),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: hero != null
                      ? _MetricValueColumn(entry: hero, heroStyle: true)
                      : Text(
                          'Feinstaub'.i18n,
                          style: Theme.of(context).textTheme.labelMedium,
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
                        if (pm1 != null && pm10 != null) const SizedBox(height: 4),
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
          if (isExpanded)
            MeasurementChartBuilder.buildExpandedChart(
              expansionKey: LatestMeasurementExpansionKey.particulate,
              history: history,
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
          _TileShell(
            selected: isExpanded,
            onTap: () => onToggle(LatestMeasurementExpansionKey.uv),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 4),
                        if (snapshot.uvb != null) _SmallMetricRow(entry: snapshot.uvb!),
                        if ((snapshot.uva != null || snapshot.uvb != null) &&
                            snapshot.uvc != null)
                          const SizedBox(height: 4),
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
          if (isExpanded)
            MeasurementChartBuilder.buildExpandedChart(
              expansionKey: LatestMeasurementExpansionKey.uv,
              history: history,
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

class _LightCompositeSection extends StatelessWidget {
  const _LightCompositeSection({
    required this.lux,
    required this.visible,
    required this.infrared,
    required this.fullSpectrum,
    required this.expandedKey,
    required this.onToggle,
    required this.history,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
  });

  final MeasurementMetricEntry? lux;
  final MeasurementMetricEntry? visible;
  final MeasurementMetricEntry? infrared;
  final MeasurementMetricEntry? fullSpectrum;
  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;
  final List<MeasuredDataPoint> history;
  final List<FlattenedDataPoint> flattenedData;
  final List<List<SensorDataPointWithTimestamp>> reshapedData;
  final Set<LDSensor> tripSensors;
  final ChartSeriesPreferences chartPrefs;

  @override
  Widget build(BuildContext context) {
    final isExpanded = expandedKey == LatestMeasurementExpansionKey.light;
    final snapshot = LightMetrics.heroFromEntries(
      lux: lux,
      visible: visible,
      infrared: infrared,
      fullSpectrum: fullSpectrum,
    );
    final sparklinePoints = MeasurementSparklineData.forLux(history: history);
    final heroUnit = lux?.unit ?? 'lx';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TileShell(
            selected: isExpanded,
            onTap: () => onToggle(LatestMeasurementExpansionKey.light),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beleuchtungsstärke'.i18n,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.heroValue != null
                            ? '${snapshot.heroFormatted} $heroUnit'
                            : snapshot.heroFormatted,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: snapshot.heroColor,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                      ),
                    ],
                  ),
                ),
                if (snapshot.hasAnyChannel) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (snapshot.visible != null)
                          _SmallMetricRow(entry: snapshot.visible!),
                        if (snapshot.visible != null && snapshot.infrared != null)
                          const SizedBox(height: 4),
                        if (snapshot.infrared != null)
                          _SmallMetricRow(entry: snapshot.infrared!),
                        if ((snapshot.visible != null || snapshot.infrared != null) &&
                            snapshot.irShareFormatted != null)
                          const SizedBox(height: 4),
                        if (snapshot.irShareFormatted != null)
                          _SmallValueRow(
                            label: 'IR-Anteil'.i18n,
                            value: snapshot.irShareFormatted!,
                            color: snapshot.irShareColor,
                          ),
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
          if (isExpanded)
            MeasurementChartBuilder.buildExpandedChart(
              expansionKey: LatestMeasurementExpansionKey.light,
              history: history,
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

/// Automatic indoor/outdoor detection from the UV bands and light channels.
class _EnvironmentContextSection extends StatelessWidget {
  const _EnvironmentContextSection({
    required this.expandedKey,
    required this.onToggle,
    required this.history,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
  });

  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;
  final List<MeasuredDataPoint> history;
  final List<FlattenedDataPoint> flattenedData;
  final List<List<SensorDataPointWithTimestamp>> reshapedData;
  final Set<LDSensor> tripSensors;
  final ChartSeriesPreferences chartPrefs;

  static String labelFor(EnvironmentContextState state) => switch (state) {
        EnvironmentContextState.outdoor => 'Außen'.i18n,
        EnvironmentContextState.indoorWindow => 'Fensterplatz'.i18n,
        EnvironmentContextState.indoor => 'Innen'.i18n,
        EnvironmentContextState.unknown => 'Unbekannt'.i18n,
      };

  @override
  Widget build(BuildContext context) {
    final analysis = EnvironmentContextClassifier.analyze(history: history);
    final latest = analysis.latest;
    if (latest == null) return const SizedBox.shrink();

    final isExpanded = expandedKey == LatestMeasurementExpansionKey.environment;
    final color = EnvironmentContextClassifier.stateColor(latest.state);
    final sparklinePoints = [
      for (final sample in analysis.samples)
        MeasurementSparklinePoint(sample.timestamp, sample.score),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TileShell(
            selected: isExpanded,
            onTap: () => onToggle(LatestMeasurementExpansionKey.environment),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Umgebung'.i18n,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            EnvironmentContextClassifier.stateIcon(latest.state),
                            color: color,
                            size: 26,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                labelFor(latest.state),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SmallValueRow(
                        label: 'Konfidenz'.i18n,
                        value: EnvironmentContextClassifier.formatConfidence(
                          latest.confidence,
                        ),
                        color: color,
                      ),
                      const SizedBox(height: 4),
                      _SmallValueRow(
                        label: 'Score'.i18n,
                        value: EnvironmentContextClassifier.formatScore(
                          latest.score,
                        ),
                        color: color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MeasurementSparkline(
                  points: sparklinePoints,
                  color: color,
                ),
              ],
            ),
          ),
          if (isExpanded)
            MeasurementChartBuilder.buildExpandedChart(
              expansionKey: LatestMeasurementExpansionKey.environment,
              history: history,
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

/// UTCI outdoors, PMV/PPD indoors — thermal comfort tile.
class _ThermalComfortSection extends StatelessWidget {
  const _ThermalComfortSection({
    required this.expandedKey,
    required this.onToggle,
    required this.history,
    required this.flattenedData,
    required this.reshapedData,
    required this.tripSensors,
    required this.chartPrefs,
  });

  final LatestMeasurementExpansionKey? expandedKey;
  final ValueChanged<LatestMeasurementExpansionKey> onToggle;
  final List<MeasuredDataPoint> history;
  final List<FlattenedDataPoint> flattenedData;
  final List<List<SensorDataPointWithTimestamp>> reshapedData;
  final Set<LDSensor> tripSensors;
  final ChartSeriesPreferences chartPrefs;

  static String _driverLabel(ThermalComfortDriver driver) => switch (driver) {
        ThermalComfortDriver.sun => 'Sonne'.i18n,
        ThermalComfortDriver.wind => 'Wind'.i18n,
        ThermalComfortDriver.humidity => 'Feuchte'.i18n,
        ThermalComfortDriver.temperature => 'Temperatur'.i18n,
        ThermalComfortDriver.none => '—',
      };

  @override
  Widget build(BuildContext context) {
    final analysis = ThermalComfortAnalysis.analyze(history: history);
    final latest = analysis.latest;
    if (latest == null) return const SizedBox.shrink();

    final reading = latest.reading;
    final isExpanded = expandedKey == LatestMeasurementExpansionKey.thermal;
    final isDegraded = reading.quality == ThermalComfortQuality.d;
    final isIndoor = reading.quality == ThermalComfortQuality.c;

    Color color;
    String heroValue;
    String subtitle;

    if (isIndoor && reading.pmv != null) {
      final band = reading.pmvBand!;
      color = band.color;
      heroValue = reading.pmv!.toStringAsFixed(1);
      subtitle = '${band.labelKey.i18n} · PPD ${reading.ppd!.round()} %';
    } else if (reading.utciC != null) {
      final band = reading.utciBand!;
      color = isDegraded ? Colors.grey.shade600 : band.color;
      heroValue = '${reading.utciC!.toStringAsFixed(1)} °C';
      subtitle = band.labelKey.i18n;
      if (reading.quality == ThermalComfortQuality.b) {
        subtitle = '$subtitle · ${'Vorbehalt'.i18n}';
      }
    } else {
      color = Colors.grey.shade600;
      heroValue = '—';
      subtitle = 'Unbekannt'.i18n;
    }

    final sparklinePoints = [
      for (final sample in analysis.samples)
        if (sample.reading.utciC != null)
          MeasurementSparklinePoint(sample.timestamp, sample.reading.utciC!),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TileShell(
            selected: isExpanded,
            onTap: () => onToggle(LatestMeasurementExpansionKey.thermal),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIndoor ? 'Behaglichkeit'.i18n : 'UTCI'.i18n,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          heroValue,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color.withValues(alpha: 0.9),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isDegraded && reading.computedAt != null)
                        Text(
                          '${'Stand'.i18n}: ${DateFormat('HH:mm').format(reading.computedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reading.tMrtC != null)
                        _SmallValueRow(
                          label: 'T_mrt'.i18n,
                          value: '${reading.tMrtC!.toStringAsFixed(1)} °C',
                          color: color,
                        ),
                      if (reading.v10Ms != null) ...[
                        const SizedBox(height: 4),
                        _SmallValueRow(
                          label: 'Wind'.i18n,
                          value: '${reading.v10Ms!.toStringAsFixed(1)} m/s',
                          color: color,
                        ),
                      ],
                      if (reading.driver != ThermalComfortDriver.none) ...[
                        const SizedBox(height: 4),
                        _SmallValueRow(
                          label: 'Treiber'.i18n,
                          value: _driverLabel(reading.driver),
                          color: color,
                        ),
                      ],
                    ],
                  ),
                ),
                if (sparklinePoints.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  MeasurementSparkline(
                    points: sparklinePoints,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
          if (isExpanded)
            MeasurementChartBuilder.buildExpandedChart(
              expansionKey: LatestMeasurementExpansionKey.thermal,
              history: history,
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

class _SmallValueRow extends StatelessWidget {
  const _SmallValueRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _SmallMetricRow extends StatelessWidget {
  const _SmallMetricRow({required this.entry});

  final MeasurementMetricEntry entry;

  @override
  Widget build(BuildContext context) {
    return _SmallValueRow(
      label: entry.label,
      value: formatMetricValueWithUnit(entry),
      color: entry.statusColor,
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
    return _TileShell(
      selected: selected,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _MetricValueColumn(entry: entry)),
          const SizedBox(width: 8),
          MeasurementSparkline(
            points: sparklinePoints,
            color: entry.statusColor,
          ),
        ],
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
    return _TileShell(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
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
        const SizedBox(height: 4),
        Text(
          formatMetricValueWithUnit(entry),
          style: (heroStyle
                  ? Theme.of(context).textTheme.headlineMedium
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(
                color: entry.statusColor,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
        ),
        if (entry.sensorSymbol.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              entry.sensorHint,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
