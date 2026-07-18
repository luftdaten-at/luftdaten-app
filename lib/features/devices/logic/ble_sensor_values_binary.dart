import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

/// Parses firmware `sensor_values` binary blocks (live BLE or badge log records).
List<SensorDataPoint> parseBleSensorValuesBinary(List<int> raw) {
  if (raw.isEmpty) return const [];

  final parsed = <SensorDataPoint>[];
  var offset = 0;
  while (offset < raw.length) {
    if (offset + 2 > raw.length) break;
    final numEntries = raw[offset + 1];
    final numBytes = 2 + numEntries * 3;
    if (offset + numBytes > raw.length) break;
    parsed.add(_parseSensorBlock(raw.sublist(offset, offset + numBytes)));
    offset += numBytes;
  }
  return parsed;
}

SensorDataPoint _parseSensorBlock(List<int> sensorData) {
  final values = <MeasurableQuantity, double>{};
  for (var i = 0; i < (sensorData.length - 2) ~/ 3; i++) {
    final dimId = sensorData[2 + i * 3];
    final rawVal = (sensorData[2 + i * 3 + 1] << 8) | sensorData[2 + i * 3 + 2];
    values[MeasurableQuantity.fromId(dimId)] = rawVal / 10.0;
  }
  _filterUsingSettings(values);
  return SensorDataPoint(sensor: LDSensor.fromId(sensorData[0]), values: values);
}

void _filterUsingSettings(Map<MeasurableQuantity, double> original) {
  if (!AppSettings.I.measurePM1) original.remove(MeasurableQuantity.pm1);
  if (!AppSettings.I.measurePM25) original.remove(MeasurableQuantity.pm25);
  if (!AppSettings.I.measurePM4) original.remove(MeasurableQuantity.pm4);
  if (!AppSettings.I.measurePM10) original.remove(MeasurableQuantity.pm10);
  if (!AppSettings.I.measureHumidity) original.remove(MeasurableQuantity.humidity);
  if (!AppSettings.I.measureTemp) original.remove(MeasurableQuantity.temperature);
  if (!AppSettings.I.measureVOC) original.remove(MeasurableQuantity.voc);
  if (!AppSettings.I.measureNOX) original.remove(MeasurableQuantity.nox);
  if (!AppSettings.I.measurePressure) original.remove(MeasurableQuantity.pressure);
  if (!AppSettings.I.measureCO2) original.remove(MeasurableQuantity.co2);
  if (!AppSettings.I.measureO3) original.remove(MeasurableQuantity.o3);
  if (!AppSettings.I.measureAQI) original.remove(MeasurableQuantity.aqi);
  if (!AppSettings.I.measureGasResistance) {
    original.remove(MeasurableQuantity.gasResistance);
  }
  if (!AppSettings.I.measureTotalVoc) original.remove(MeasurableQuantity.totalVoc);
}
