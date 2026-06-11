import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_display_defaults.dart';

class MeasurementValuesPreferences extends ChangeNotifier {
  static const _storageKey = 'measurementValuesVisibility';

  final GetStorage _box = GetStorage('settings');
  Map<String, bool> _visibility = {};

  void init() {
    _load();
  }

  void _load() {
    final raw = _box.read(_storageKey);
    if (raw is! Map) {
      _visibility = {};
      return;
    }
    _visibility = raw.map((key, value) => MapEntry(key.toString(), value == true));
  }

  void _persist() {
    _box.write(_storageKey, _visibility);
  }

  bool defaultVisible({
    required String seriesKey,
    required Set<LDSensor> tripSensors,
    LDSensor? sensor,
    MeasurableQuantity? quantity,
  }) {
    if (sensor != null && quantity != null) {
      return MeasurementDisplayDefaults.defaultSeriesVisible(
        sensor: sensor,
        quantity: quantity,
        tripSensors: tripSensors,
      );
    }
    final parts = seriesKey.split(':');
    if (parts.length != 2) return true;
    final parsedSensor = LDSensor.fromName(parts[0]);
    final parsedQuantity = MeasurableQuantity.values
        .where((q) => q.toString().split('.').last == parts[1])
        .firstOrNull;
    if (parsedSensor == LDSensor.unknown || parsedQuantity == null) return true;
    return MeasurementDisplayDefaults.defaultSeriesVisible(
      sensor: parsedSensor,
      quantity: parsedQuantity,
      tripSensors: tripSensors,
    );
  }

  bool isVisible(
    String seriesKey, {
    required Set<LDSensor> tripSensors,
    LDSensor? sensor,
    MeasurableQuantity? quantity,
    bool? defaultValue,
  }) {
    final fallback = defaultValue ??
        defaultVisible(
          seriesKey: seriesKey,
          tripSensors: tripSensors,
          sensor: sensor,
          quantity: quantity,
        );
    if (!_visibility.containsKey(seriesKey)) {
      return fallback;
    }
    return _visibility[seriesKey]!;
  }

  void setVisible(String seriesKey, bool visible) {
    _visibility[seriesKey] = visible;
    _persist();
    notifyListeners();
  }

  void setAll(Map<String, bool> values) {
    for (final entry in values.entries) {
      _visibility[entry.key] = entry.value;
    }
    _persist();
    notifyListeners();
  }

  Map<String, bool> visibilityFor(Iterable<String> seriesKeys) {
    return {
      for (final key in seriesKeys)
        if (_visibility.containsKey(key)) key: _visibility[key]!,
    };
  }
}
