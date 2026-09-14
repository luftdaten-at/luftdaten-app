import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/data/sensor_calibration.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

class DeviceCalibrationStore extends ChangeNotifier {
  DeviceCalibrationStore({GetStorage? box}) : _box = box ?? GetStorage('deviceCalibration');

  static const _storageKey = 'records';

  final GetStorage _box;
  Map<String, DeviceCalibrationRecord> _records = {};

  Future<void> init() async {
    await GetStorage.init('deviceCalibration');
    _load();
  }

  void _load() {
    final raw = _box.read(_storageKey);
    if (raw is! Map) {
      _records = {};
      return;
    }
    _records = raw.map(
      (key, value) => MapEntry(
        key.toString(),
        DeviceCalibrationRecord.fromJson((value as Map).cast<String, dynamic>()),
      ),
    );
  }

  void _persist() {
    _box.write(
      _storageKey,
      _records.map((key, value) => MapEntry(key, value.toJson())),
    );
  }

  DeviceSensorOffset? getOffset(
    String bleName,
    LDSensor sensor,
    MeasurableQuantity quantity,
  ) {
    final key = deviceSensorOffsetKey(sensor, quantity);
    return _records[bleName]?.offsets[key];
  }

  List<DeviceSensorOffset> offsetsForDevice(String bleName) {
    return _records[bleName]?.offsets.values.toList() ?? const [];
  }

  void setOffset(String bleName, DeviceSensorOffset offset) {
    final record = _records[bleName] ??
        DeviceCalibrationRecord(bleName: bleName);
    final key = deviceSensorOffsetKey(offset.sensor, offset.quantity);
    final nextOffsets = Map<String, DeviceSensorOffset>.from(record.offsets)
      ..[key] = offset;
    _records[bleName] = record.copyWith(offsets: nextOffsets);
    _persist();
    notifyListeners();
  }

  void clearOffset(
    String bleName,
    LDSensor sensor,
    MeasurableQuantity quantity,
  ) {
    final record = _records[bleName];
    if (record == null) return;
    final key = deviceSensorOffsetKey(sensor, quantity);
    if (!record.offsets.containsKey(key)) return;
    final nextOffsets = Map<String, DeviceSensorOffset>.from(record.offsets)
      ..remove(key);
    if (nextOffsets.isEmpty) {
      _records.remove(bleName);
    } else {
      _records[bleName] = record.copyWith(offsets: nextOffsets);
    }
    _persist();
    notifyListeners();
  }
}
