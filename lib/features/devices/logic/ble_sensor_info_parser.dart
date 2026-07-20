import 'package:convert/convert.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

/// Badge firmware stub when no measurement has refreshed `sensor_info` yet.
const int bleSensorInfoStubByte = 0x06;

bool isBleSensorInfoStub(List<int> raw) {
  return raw.isEmpty || (raw.length == 1 && raw.first == bleSensorInfoStubByte);
}

List<SensorDetails> parseSensorsFromDeviceInfoJson(Map<String, dynamic> info) {
  final sensorList = info['sensor_list'];
  if (sensorList is! List) return const [];

  final out = <SensorDetails>[];
  for (final entry in sensorList) {
    if (entry is! Map) continue;
    final map = Map<String, dynamic>.from(entry);
    final modelId = map['model_id'] ?? map['model'];
    if (modelId is! int) continue;
    final model = LDSensor.fromId(modelId);
    if (model == LDSensor.unknown) continue;

    final serial = map['serial_number'] ?? map['serial'];
    out.add(SensorDetails(
      model,
      serialNumber: serial is String && serial.isNotEmpty ? serial : null,
    ));
  }
  return out;
}

List<SensorDetails> parseSensorsFromDeviceInfoBinary(List<int> raw) {
  if (raw.length < 10) return const [];

  final count = raw[9];
  if (count <= 0) return const [];
  if (raw.length < 10 + count * 2) return const [];

  final out = <SensorDetails>[];
  for (var i = 0; i < count; i++) {
    final model = LDSensor.fromId(raw[10 + i * 2]);
    final status = raw[11 + i * 2];
    if (model == LDSensor.unknown || status == 0) continue;
    out.add(SensorDetails(model));
  }
  return out;
}

List<SensorDetails> parseSensorsFromSensorInfoCharacteristic(List<int> raw) {
  if (isBleSensorInfoStub(raw)) return const [];

  final sensorDetailsParts = _splitOnByte(raw, 0xff);
  final out = <SensorDetails>[];
  for (var i = 0; i < sensorDetailsParts.length / 2; i++) {
    final sensorSpec = sensorDetailsParts[i * 2];
    final sensorDetails = sensorDetailsParts[i * 2 + 1];
    if (sensorSpec.isEmpty) continue;
    final model = LDSensor.fromId(sensorSpec[0]);
    if (model == LDSensor.unknown) continue;

    if ((model == LDSensor.sen5x || model == LDSensor.sen66) && sensorDetails.length >= 6) {
      out.add(SensorDetails(
        model,
        firmwareVersion: '${sensorDetails[0]}.${sensorDetails[1]}',
        hardwareVersion: '${sensorDetails[2]}.${sensorDetails[3]}',
        protocolVersion: '${sensorDetails[4]}.${sensorDetails[5]}',
        serialNumber: sensorDetails.length > 6 ? String.fromCharCodes(sensorDetails.sublist(6)) : '',
      ));
    } else if (model == LDSensor.sht4x) {
      out.add(SensorDetails(
        model,
        serialNumber: hex.encode(sensorDetails),
      ));
    } else {
      out.add(SensorDetails(model));
    }
  }
  return out;
}

List<List<int>> _splitOnByte(List<int> raw, int delimiter) {
  final result = <List<int>>[];
  var current = <int>[];
  for (final byte in raw) {
    if (byte == delimiter) {
      result.add(current);
      current = [];
    } else {
      current.add(byte);
    }
  }
  if (current.isNotEmpty) {
    result.add(current);
  }
  return result;
}
