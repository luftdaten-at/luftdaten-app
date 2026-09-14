import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/logic/device_calibration_store.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

SensorDataPoint applySensorCalibration(
  String bleName,
  SensorDataPoint point, {
  DeviceCalibrationStore? store,
}) {
  final calibrationStore = store ?? getIt<DeviceCalibrationStore>();
  final offsets = calibrationStore.offsetsForDevice(bleName);
  if (offsets.isEmpty) return point;

  final corrected = Map<MeasurableQuantity, double>.from(point.values);
  for (final offset in offsets) {
    if (offset.sensor != point.sensor) continue;
    final quantity = offset.quantity;
    final raw = corrected[quantity];
    if (raw == null) continue;
    corrected[quantity] = raw + offset.offset;
  }

  return SensorDataPoint(sensor: point.sensor, values: corrected);
}

List<SensorDataPoint> applySensorCalibrationToPoints(
  String bleName,
  List<SensorDataPoint> points, {
  DeviceCalibrationStore? store,
}) {
  return points
      .map((point) => applySensorCalibration(bleName, point, store: store))
      .toList(growable: false);
}

List<dynamic> applySensorCalibrationToReadResult(
  String bleName,
  List<dynamic> result, {
  DeviceCalibrationStore? store,
}) {
  if (result.isEmpty) return result;

  if (result.first is List<SensorDataPoint>) {
    final calibrated = applySensorCalibrationToPoints(
      bleName,
      List<SensorDataPoint>.from(result.first as List),
      store: store,
    );
    if (result.length == 1) return [calibrated];
    return [calibrated, ...result.sublist(1)];
  }

  if (result.first is SensorDataPoint) {
    final calibrated = applySensorCalibrationToPoints(
      bleName,
      List<SensorDataPoint>.from(result.cast<SensorDataPoint>()),
      store: store,
    );
    return [calibrated, <String, dynamic>{}];
  }

  return result;
}
