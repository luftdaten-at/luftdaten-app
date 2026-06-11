import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_display_defaults.dart';

enum ChartSeriesChartId {
  particulate,
  temperature,
  humidity,
  voc,
  totalVoc,
  nox,
  pressure,
  co2,
  o3,
  aqi,
  gasResistance,
}

/// Stable series keys persisted in GetStorage.
class ChartSeriesKeys {
  ChartSeriesKeys._();

  static const mean = 'mean';
  static const pm1 = 'PM1.0';
  static const pm25 = 'PM2.5';
  static const pm4 = 'PM4.0';
  static const pm10 = 'PM10.0';
}

class ChartSeriesOption {
  const ChartSeriesOption({required this.key, required this.label});

  final String key;
  final String label;
}

class ChartSeriesPreferences extends ChangeNotifier {
  static const _storageKey = 'chartSeriesVisibility';

  final GetStorage _box = GetStorage('settings');
  Map<String, Map<String, bool>> _visibility = {};

  void init() {
    _load();
  }

  void _load() {
    final raw = _box.read(_storageKey);
    if (raw is! Map) {
      _visibility = {};
      return;
    }
    _visibility = raw.map((chartKey, chartValue) {
      if (chartValue is! Map) {
        return MapEntry(chartKey.toString(), <String, bool>{});
      }
      return MapEntry(
        chartKey.toString(),
        chartValue.map((seriesKey, visible) {
          return MapEntry(seriesKey.toString(), visible == true);
        }),
      );
    });
  }

  void _persist() {
    _box.write(_storageKey, _visibility);
  }

  String _chartKey(ChartSeriesChartId chart) => chart.name;

  /// Default series visibility when the user has not saved a preference yet.
  bool defaultVisible(
    ChartSeriesChartId chart,
    String seriesKey, {
    Set<LDSensor>? tripSensors,
  }) {
    if (chart == ChartSeriesChartId.particulate && seriesKey == ChartSeriesKeys.pm4) {
      return false;
    }
    if (tripSensors != null && seriesKey != ChartSeriesKeys.mean) {
      final sensor = LDSensor.fromName(seriesKey);
      if (sensor != LDSensor.unknown) {
        return MeasurementDisplayDefaults.defaultSeriesVisible(
          sensor: sensor,
          chartId: chart,
          tripSensors: tripSensors,
        );
      }
    }
    return true;
  }

  bool isVisible(
    ChartSeriesChartId chart,
    String seriesKey, {
    Set<LDSensor>? tripSensors,
    bool? defaultValue,
  }) {
    final chartMap = _visibility[_chartKey(chart)];
    final fallback = defaultValue ?? defaultVisible(chart, seriesKey, tripSensors: tripSensors);
    if (chartMap == null || !chartMap.containsKey(seriesKey)) {
      return fallback;
    }
    return chartMap[seriesKey]!;
  }

  void setVisible(ChartSeriesChartId chart, String seriesKey, bool visible) {
    final key = _chartKey(chart);
    _visibility.putIfAbsent(key, () => {});
    _visibility[key]![seriesKey] = visible;
    _persist();
    notifyListeners();
  }

  void setAll(ChartSeriesChartId chart, Map<String, bool> values) {
    _visibility[_chartKey(chart)] = Map<String, bool>.from(values);
    _persist();
    notifyListeners();
  }

  Map<String, bool> visibilityFor(ChartSeriesChartId chart) {
    final stored = _visibility[_chartKey(chart)];
    if (stored == null) return {};
    return Map<String, bool>.from(stored);
  }
}
