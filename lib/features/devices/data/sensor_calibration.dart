import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

/// Persisted additive correction for one sensor quantity on one device.
class DeviceSensorOffset {
  const DeviceSensorOffset({
    required this.sensor,
    required this.quantity,
    required this.offset,
    required this.calibratedAt,
    this.note,
    this.rawAtCalibration,
    this.targetAtCalibration,
  });

  final LDSensor sensor;
  final MeasurableQuantity quantity;
  final double offset;
  final DateTime calibratedAt;
  final String? note;
  final double? rawAtCalibration;
  final double? targetAtCalibration;

  Map<String, dynamic> toJson() => {
        'sensor': sensor.name,
        'quantity': quantity.name,
        'offset': offset,
        'calibratedAt': calibratedAt.toIso8601String(),
        if (note != null) 'note': note,
        if (rawAtCalibration != null) 'rawAtCalibration': rawAtCalibration,
        if (targetAtCalibration != null) 'targetAtCalibration': targetAtCalibration,
      };

  factory DeviceSensorOffset.fromJson(Map<String, dynamic> json) {
    return DeviceSensorOffset(
      sensor: LDSensor.fromName(json['sensor'] as String),
      quantity: MeasurableQuantity.values.firstWhere(
        (q) => q.name == json['quantity'],
      ),
      offset: (json['offset'] as num).toDouble(),
      calibratedAt: DateTime.parse(json['calibratedAt'] as String),
      note: json['note'] as String?,
      rawAtCalibration: (json['rawAtCalibration'] as num?)?.toDouble(),
      targetAtCalibration: (json['targetAtCalibration'] as num?)?.toDouble(),
    );
  }
}

/// All app-side offsets stored for one BLE device (keyed by [bleName]).
class DeviceCalibrationRecord {
  const DeviceCalibrationRecord({
    required this.bleName,
    this.offsets = const {},
  });

  final String bleName;
  final Map<String, DeviceSensorOffset> offsets;

  DeviceCalibrationRecord copyWith({
    Map<String, DeviceSensorOffset>? offsets,
  }) {
    return DeviceCalibrationRecord(
      bleName: bleName,
      offsets: offsets ?? this.offsets,
    );
  }

  Map<String, dynamic> toJson() => {
        'bleName': bleName,
        'offsets': offsets.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory DeviceCalibrationRecord.fromJson(Map<String, dynamic> json) {
    final rawOffsets = (json['offsets'] as Map?)?.cast<String, dynamic>() ?? {};
    return DeviceCalibrationRecord(
      bleName: json['bleName'] as String,
      offsets: rawOffsets.map(
        (key, value) => MapEntry(
          key,
          DeviceSensorOffset.fromJson((value as Map).cast<String, dynamic>()),
        ),
      ),
    );
  }
}

String deviceSensorOffsetKey(LDSensor sensor, MeasurableQuantity quantity) {
  return '${sensor.name}:${quantity.name}';
}
