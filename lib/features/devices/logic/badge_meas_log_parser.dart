import 'dart:typed_data';

import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_sensor_values_binary.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

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

/// Parses badge LDLG binary blob into firmware-style Datahub JSON objects.
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
