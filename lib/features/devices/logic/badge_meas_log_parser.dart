import 'dart:typed_data';

import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';
import 'package:luftdaten.at/features/devices/logic/ble_sensor_values_binary.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';

class BadgeMeasLogHeader {
  const BadgeMeasLogHeader({
    required this.recordCount,
    required this.recordSize,
    required this.sessionMs0,
  });

  final int recordCount;
  final int recordSize;
  final int sessionMs0;

  int get totalBytes => 64 + recordCount * recordSize;

  static BadgeMeasLogHeader? parse(Uint8List bytes) {
    if (bytes.length < 64) return null;
    if (bytes[0] != 0x4c || bytes[1] != 0x44 || bytes[2] != 0x4c || bytes[3] != 0x47) {
      return null;
    }
    if (bytes[4] != 1) return null;
    return BadgeMeasLogHeader(
      recordCount: _u32le(bytes, 6),
      recordSize: bytes[10] | (bytes[11] << 8),
      sessionMs0: _u32le(bytes, 12),
    );
  }
}

class BadgeMeasLogImportResult {
  const BadgeMeasLogImportResult._({
    required this.ok,
    this.lines = const [],
    this.errorMessage,
  });

  const BadgeMeasLogImportResult.success(this.lines)
      : ok = true,
        errorMessage = null;

  factory BadgeMeasLogImportResult.error(String message) {
    return BadgeMeasLogImportResult._(
      ok: false,
      lines: const [],
      errorMessage: message,
    );
  }

  final bool ok;
  final List<Map<String, dynamic>> lines;
  final String? errorMessage;
}

/// Parses badge LDLG binary blob into firmware-style `{device, sensors}` JSON lines.
BadgeMeasLogImportResult parseBadgeMeasLogToDatahubJson({
  required Uint8List bytes,
  required BleDevice device,
  DateTime? importTime,
}) {
  final header = BadgeMeasLogHeader.parse(bytes);
  if (header == null) {
    return BadgeMeasLogImportResult.error('Ungültiges Messprotokoll-Format.');
  }
  if (bytes.length < header.totalBytes) {
    return BadgeMeasLogImportResult.error('Messprotokoll unvollständig.');
  }

  final endTime = (importTime ?? DateTime.now()).toUtc();
  const interval = Duration(seconds: 30);
  final lines = <Map<String, dynamic>>[];

  var offset = 64;
  for (var i = 0; i < header.recordCount; i++) {
    if (offset + header.recordSize > bytes.length) break;

    final valuesLen = bytes[offset + 6] | (bytes[offset + 7] << 8);
    final valuesStart = offset + 8;
    final valuesEnd = valuesStart + valuesLen;
    if (valuesEnd > offset + header.recordSize) {
      return BadgeMeasLogImportResult.error('Ungültiger Datensatz $i.');
    }

    final sensorPoints = parseBleSensorValuesBinary(bytes.sublist(valuesStart, valuesEnd));
    final sensors = _sensorsMapFromPoints(sensorPoints);
    if (sensors.isEmpty) {
      offset += header.recordSize;
      continue;
    }

    final recordIndexFromEnd = header.recordCount - 1 - i;
    final time = endTime.subtract(interval * recordIndexFromEnd);

    lines.add({
      'device': {
        'time': time.toIso8601String(),
        'id': device.chipIdForApi,
        'firmware': device.firmwareVersion?.toString() ?? '0.0.0',
        'model': device.model.id,
        if (device.apiKey != null && device.apiKey!.isNotEmpty) 'apikey': device.apiKey,
      },
      'sensors': sensors,
    });

    offset += header.recordSize;
  }

  if (lines.isEmpty) {
    return BadgeMeasLogImportResult.error('Keine gültigen Messzeilen gefunden.');
  }

  return BadgeMeasLogImportResult.success(lines);
}

/// Converts parsed badge log lines into a [Trip] for display in Messwerte.
Trip? badgeMeasLogLinesToTrip({
  required List<Map<String, dynamic>> lines,
  required BleDevice device,
}) {
  if (lines.isEmpty) return null;

  final points = <MeasuredDataPoint>[];
  for (final line in lines) {
    final deviceBlock = line['device'];
    final sensorsBlock = line['sensors'];
    if (deviceBlock is! Map || sensorsBlock is! Map) continue;

    final timeRaw = deviceBlock['time'];
    if (timeRaw is! String) continue;
    final timestamp = DateTime.tryParse(timeRaw);
    if (timestamp == null) continue;

    final sensorData = <SensorDataPoint>[];
    for (final entry in sensorsBlock.entries) {
      if (entry.value is! Map) continue;
      final sensorMap = entry.value as Map;
      final typeId = sensorMap['type'];
      final data = sensorMap['data'];
      if (typeId is! int || data is! Map) continue;

      final sensor = LDSensor.fromId(typeId);
      if (sensor == LDSensor.unknown) continue;

      final values = <MeasurableQuantity, double>{};
      for (final dimension in data.entries) {
        final quantityId = int.tryParse(dimension.key.toString());
        if (quantityId == null) continue;
        final quantity = MeasurableQuantity.fromId(quantityId);
        if (quantity == MeasurableQuantity.unknown) continue;
        final rawValue = dimension.value;
        if (rawValue is num) {
          final v = rawValue.toDouble();
          if (!v.isNaN && !v.isInfinite) values[quantity] = v;
        }
      }
      if (values.isNotEmpty) {
        sensorData.add(SensorDataPoint(sensor: sensor, values: values));
      }
    }

    if (sensorData.isEmpty) continue;
    points.add(MeasuredDataPoint(timestamp: timestamp, sensorData: sensorData));
  }

  if (points.isEmpty) return null;
  points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  return Trip.withData(
    deviceDisplayName: device.displayName,
    deviceFourLetterCode: device.fourLetterCode,
    deviceChipId: ChipId.fromChipId(device.chipIdForApi),
    deviceModel: device.model,
    sensorDetails: device.availableSensors,
    data: points,
  )..isImported = true;
}

/// Estimated UTC timestamps for badge log records (30 s apart, same as import).
List<DateTime> badgeMeasLogEstimatedRecordTimes({
  required int recordCount,
  DateTime? endTime,
}) {
  if (recordCount <= 0) return const [];
  final end = (endTime ?? DateTime.now()).toUtc();
  const interval = Duration(seconds: 30);
  return List.generate(recordCount, (i) {
    final recordIndexFromEnd = recordCount - 1 - i;
    return end.subtract(interval * recordIndexFromEnd);
  });
}

Map<String, dynamic> _sensorsMapFromPoints(List<SensorDataPoint> points) {
  final sensors = <String, dynamic>{};
  var idx = 0;
  for (final sp in points) {
    if (sp.sensor == LDSensor.unknown) continue;
    final data = <String, dynamic>{};
    for (final entry in sp.values.entries) {
      if (entry.key == MeasurableQuantity.unknown) continue;
      final v = entry.value;
      data['${entry.key.id}'] = (v.isNaN || v.isInfinite) ? null : v;
    }
    if (data.isEmpty) continue;
    idx++;
    sensors['$idx'] = {
      'type': sp.sensor.id,
      'data': data,
    };
  }
  return sensors;
}

int _u32le(Uint8List raw, int offset) {
  return raw[offset] |
      (raw[offset + 1] << 8) |
      (raw[offset + 2] << 16) |
      (raw[offset + 3] << 24);
}
