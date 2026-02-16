import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/measurements/data/latlng_with_precision.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.i18n.dart';

enum LDSensor {
  sen5x(
    1,
    [
      MeasurableQuantity.pm1,
      MeasurableQuantity.pm25,
      MeasurableQuantity.pm4,
      MeasurableQuantity.pm10,
      MeasurableQuantity.humidity,
      MeasurableQuantity.temperature,
      MeasurableQuantity.voc,
      MeasurableQuantity.nox,
    ],
    'Sensirion Sen5x',
    'Sen5x',
  ),
  bmp280(
    2,
    [
      MeasurableQuantity.temperature,
      MeasurableQuantity.pressure,
    ],
    'Bosch Sensortec BMP280',
    'BMP280',
  ),
  bme280(
    3,
    [
      MeasurableQuantity.temperature,
      MeasurableQuantity.pressure,
      MeasurableQuantity.humidity,
    ],
    'Bosch Sensortec BME280',
    'BME280',
  ),
  bme680(
    4,
    [
      MeasurableQuantity.temperature,
      MeasurableQuantity.pressure,
      MeasurableQuantity.humidity,
      MeasurableQuantity.gasResistance,
    ],
    'Bosch Sensortec BME680',
    'BME680',
  ),
  scd4x(
    5,
    [
      MeasurableQuantity.temperature,
      MeasurableQuantity.humidity,
      MeasurableQuantity.co2,
    ],
    'Sensirion SCD4x',
    'SCD4x',
  ),
  aht20(
    6,
    [
      MeasurableQuantity.temperature,
      MeasurableQuantity.humidity,
    ],
    'Aosong AHT20',
    'AHT20',
  ),
  sht30(
    7,
    [
      MeasurableQuantity.temperature,
      MeasurableQuantity.humidity,
    ],
    'Sensirion SHT30',
    'SHT30',
  ),
  sht31(
    8,
    [
      MeasurableQuantity.temperature,
      MeasurableQuantity.humidity,
    ],
    'Sensirion SHT31',
    'SHT31',
  ),
  ags02ma(
    9,
    [
      MeasurableQuantity.totalVoc,
      MeasurableQuantity.gasResistance,
    ],
    'Aosong AGS02MA',
    'AGS02MA',
  ),
  sht4x(
    9,
    [
      MeasurableQuantity.temperature,
      MeasurableQuantity.humidity,
    ],
    'Sensirion SHT4x',
    'SHT4x',
  ),
  sgp40(
    10,
    [
      MeasurableQuantity.temperature,
      MeasurableQuantity.humidity,
    ],
    'Sensirion SHT4x',
    'SHT4x',
  ),
  unknown(
    999,
    [],
    'Unbekannt',
    'Unknown',
  ),
  all(
    0,
    MeasurableQuantity.values,
    'Alle Sensoren',
    'Alle',
  );

  const LDSensor(this.id, this.measures, this.longName, this.shortName);

  final int id;
  final List<MeasurableQuantity> measures;
  final String longName;
  final String shortName;

  String get name => toString().split('.').last;

  factory LDSensor.fromId(int id) => LDSensor.values.where((e) => e.id == id).firstOrNull ?? LDSensor.unknown;

  factory LDSensor.fromName(String name) => LDSensor.values.where((e) => e.name == name).firstOrNull ?? LDSensor.unknown;
}

enum MeasurableQuantity {
  unknown(0, 0, 0, 'Unbekannt', 'Unknown', ''),
  pm01(1, 15, 45, 'PM0.1', 'PM0.1', 'µg/m³'),
  pm1(2, 5, 15, 'PM1.0', 'PM1.0', 'µg/m³'),
  pm25(3, 5, 15, 'PM2.5', 'PM2.5', 'µg/m³'), // TODO these are the WHO limits, but are they too low for the map
  pm4(4, 15, 45, 'PM4.0', 'PM4.0', 'µg/m³'),
  pm10(5, 15, 45, 'PM10.0', 'PM10.0', 'µg/m³'),
  humidity(6, 100, 100, 'Luftfeuchtigkeit', 'Rel. Humidity', '%'),
  temperature(7, 30, 40, 'Temperatur', 'Temperature', '°C'),
  voc(8, 200, 400, 'VOCs', 'VOC Index', 'Index'),
  nox(9, 200, 400, 'NOx', 'NOx Index', 'Index'),
  pressure(10, 10000, 10000, 'Luftdruck', 'Pressure', 'hPa'),
  co2(11, 1000, 2000, 'CO2', 'CO2', 'ppb'),
  o3(12, 100, 200, 'O3', 'O3', 'ppb'),
  aqi(13, 30, 200, 'AQI', 'AQI', 'Index'),
  gasResistance(14, 100, 200, 'Gaswiderstand', 'Gas Resistance', 'kOhm'), // TODO is this true unit?
  totalVoc(15, 200, 400, 'VOCs (absolut)', 'VOCs', 'ppb'),
  no2(16, 100, 200, 'NO2', 'NO2', 'ppb'),
  sgp40RawGasIndex(17, 100, 200, 'SGP40 Gas-Index (Rohwert)', 'Raw Gas', 'Log.'),
  sgp40AdjustedGasIndex(18, 100, 200, 'SGP40 Gas-Index (adjustiert)', 'Adjusted Gas', 'Log.');

  const MeasurableQuantity(this.id, this.elevatedLimit, this.highLimit, this._name, this.csvName, this.csvUnit);

  final int id, elevatedLimit, highLimit;
  final String _name, csvName, csvUnit;

  String get name => _name.i18n;

  factory MeasurableQuantity.fromId(int id) =>
      MeasurableQuantity.values.where((e) => e.id == id).firstOrNull ?? MeasurableQuantity.unknown;
}

class MeasuredDataPoint {
  final DateTime timestamp;
  String? annotation;
  LatLngWithPrecision? location;
  final List<SensorDataPoint> sensorData;
  MobilityModes? mode;
  Map<String, dynamic>? j;

  MeasuredDataPoint({
    required this.timestamp,
    required this.sensorData,
    this.location,
    this.annotation,
    this.mode,
    this.j,
  });

  FlattenedDataPoint get flatten {
    Map<MeasurableQuantity, double> values = {};
    // Sort data so that Sen5x is read first and other temperature measurements can override this
    sensorData.sort((a, b) => a.sensor.id.compareTo(b.sensor.id));
    for (SensorDataPoint sensorDataPoint in sensorData) {
      values.addAll(sensorDataPoint.values);
    }
    return FlattenedDataPoint.fromMap(
      values: values,
      timestamp: timestamp,
      location: location,
      annotation: annotation,
      mode: mode,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        if (annotation != null) 'annotation': annotation,
        if (location != null) 'location': location!.toJson(),
        'sensorData': sensorData.map((e) => e.toJson).toList(),
        if (mode != null) 'mode': mode!.name,
      };

  factory MeasuredDataPoint.fromJson(Map<String, dynamic> json) {
    return MeasuredDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      annotation: json['annotation'],
      location: json['location'] != null ? LatLngWithPrecision.fromJson(json['location']) : null,
      sensorData: (json['sensorData'] as List).map((e) => e as Map<String, dynamic>).map((e) {
        LDSensor sensor = LDSensor.fromName(e['sensor']);
        switch (sensor) {
          case LDSensor.all:
            return FlattenedDataPoint.fromJson(e);
          default:
            return SensorDataPoint.fromJson(e);
        }
      }).toList(),
      mode: json['mode'] != null ? MobilityModes.fromName(json['mode']) : null,
    );
  }

  factory MeasuredDataPoint.fromCsv(String csv) {
    List<String> parts = csv.split(',');
    bool includeMode = parts.length > 12;
    return MeasuredDataPoint(
      timestamp: DateTime.parse(parts[0]),
      sensorData: [
        FlattenedDataPoint.fromCsv(csv),
      ],
      location: parts[10].isNotEmpty && parts[11].isNotEmpty
          ? LatLngWithPrecision(double.parse(parts[10]), double.parse(parts[11]), null)
          : null,
      mode: includeMode ? (parts[12].isNotEmpty ? MobilityModes.fromName(parts[12]) : null) : null,
      annotation: parts[includeMode ? 13 : 12].isNotEmpty ? parts[includeMode ? 13 : 12] : null,
    );
  }

  List<String> toCsv() {
    List<String> csv = [];
    for(SensorDataPoint sensorDataPoint in sensorData) {
      csv.addAll(sensorDataPoint.toCsv([
        timestamp.toIso8601String(),
        location?.latitude.toString() ?? '',
        location?.longitude.toString() ?? '',
      ]));
    }
    return csv;
  }
}

class SensorDataPoint {
  final Map<MeasurableQuantity, double> values;

  final LDSensor sensor;

  const SensorDataPoint({required this.sensor, required this.values});

  Map<String, dynamic> get toJson => {
        'sensor': sensor.name,
        ...values.map((key, value) => MapEntry(key.name, value)),
      };

  SensorDataPoint.fromJson(Map<String, dynamic> json)
      : sensor = LDSensor.fromName(json['sensor']),
        values = {
          for (MeasurableQuantity quantity in MeasurableQuantity.values)
            if (json.containsKey(quantity.name)) quantity: json[quantity.name],
        };

  // TODO this currently does not support user-defined comments
  List<String> toCsv(List<String> header) {
    List<String> csv = [];
    for(MeasurableQuantity quantity in values.keys) {
      List<String> items = [];
      items.addAll(header);
      items.add(sensor.name);
      items.add(quantity.csvName);
      items.add(quantity.csvUnit);
      items.add(values[quantity].toString());
      csv.add(items.join(','));
    }
    return csv;
  }
}

class FlattenedDataPoint extends SensorDataPoint {
  final double? pm1,
      pm25,
      pm4,
      pm10,
      humidity,
      temperature,
      voc,
      nox,
      pressure,
      co2,
      o3,
      totalVoc,
      gasResistance;
  final int? aqi;
  final DateTime timestamp;
  final String? annotation;
  final LatLngWithPrecision? location;
  final MobilityModes? mode;

  FlattenedDataPoint({
    this.pm1,
    this.pm25,
    this.pm4,
    this.pm10,
    this.humidity,
    this.temperature,
    this.voc,
    this.nox,
    this.pressure,
    this.co2,
    this.o3,
    this.aqi,
    this.totalVoc,
    this.gasResistance,
    required this.timestamp,
    this.annotation,
    this.location,
    this.mode,
  }) : super(sensor: LDSensor.all, values: {
          if (pm1 != null) MeasurableQuantity.pm1: pm1,
          if (pm25 != null) MeasurableQuantity.pm25: pm25,
          if (pm4 != null) MeasurableQuantity.pm4: pm4,
          if (pm10 != null) MeasurableQuantity.pm10: pm10,
          if (humidity != null) MeasurableQuantity.humidity: humidity,
          if (temperature != null) MeasurableQuantity.temperature: temperature,
          if (voc != null) MeasurableQuantity.voc: voc,
          if (nox != null) MeasurableQuantity.nox: nox,
          if (pressure != null) MeasurableQuantity.pressure: pressure,
          if (co2 != null) MeasurableQuantity.co2: co2,
          if (o3 != null) MeasurableQuantity.o3: o3,
          if (aqi != null) MeasurableQuantity.aqi: aqi.toDouble(),
          if (totalVoc != null) MeasurableQuantity.totalVoc: totalVoc,
          if (gasResistance != null) MeasurableQuantity.gasResistance: gasResistance,
        });

  factory FlattenedDataPoint.fromMap({
    required DateTime timestamp,
    String? annotation,
    LatLngWithPrecision? location,
    required Map<MeasurableQuantity, double> values,
    MobilityModes? mode,
  }) {
    return FlattenedDataPoint(
      timestamp: timestamp,
      annotation: annotation,
      location: location,
      pm1: values[MeasurableQuantity.pm1],
      pm25: values[MeasurableQuantity.pm25],
      pm4: values[MeasurableQuantity.pm4],
      pm10: values[MeasurableQuantity.pm10],
      humidity: values[MeasurableQuantity.humidity],
      temperature: values[MeasurableQuantity.temperature],
      voc: values[MeasurableQuantity.voc],
      nox: values[MeasurableQuantity.nox],
      pressure: values[MeasurableQuantity.pressure],
      co2: values[MeasurableQuantity.co2],
      o3: values[MeasurableQuantity.o3],
      aqi: values[MeasurableQuantity.aqi]?.round(),
      totalVoc: values[MeasurableQuantity.totalVoc],
      gasResistance: values[MeasurableQuantity.gasResistance],
      mode: mode,
    );
  }

  @override
  Map<MeasurableQuantity, double> get values => {
        if (pm1 != null) MeasurableQuantity.pm1: pm1!,
        if (pm25 != null) MeasurableQuantity.pm25: pm25!,
        if (pm4 != null) MeasurableQuantity.pm4: pm4!,
        if (pm10 != null) MeasurableQuantity.pm10: pm10!,
        if (humidity != null) MeasurableQuantity.humidity: humidity!,
        if (temperature != null) MeasurableQuantity.temperature: temperature!,
        if (voc != null) MeasurableQuantity.voc: voc!,
        if (nox != null) MeasurableQuantity.nox: nox!,
        if (pressure != null) MeasurableQuantity.pressure: pressure!,
        if (co2 != null) MeasurableQuantity.co2: co2!,
        if (o3 != null) MeasurableQuantity.o3: o3!,
        if (aqi != null) MeasurableQuantity.aqi: aqi!.toDouble(),
        if (totalVoc != null) MeasurableQuantity.totalVoc: totalVoc!,
        if (gasResistance != null) MeasurableQuantity.gasResistance: gasResistance!,
      };

  @override
  Map<String, dynamic> get toJson => {
        'sensor': sensor.id,
        'sensorName': sensor.name,
        if (pm1 != null) 'pm1': pm1,
        if (pm25 != null) 'pm25': pm25,
        if (pm4 != null) 'pm4': pm4,
        if (pm10 != null) 'pm10': pm10,
        if (humidity != null) 'humidity': humidity,
        if (temperature != null) 'temperature': temperature,
        if (voc != null) 'voc': voc,
        if (nox != null) 'nox': nox,
        if (pressure != null) 'pressure': pressure,
        if (co2 != null) 'co2': co2,
        if (o3 != null) 'o3': o3,
        if (aqi != null) 'aqi': aqi,
        if (totalVoc != null) 'totalVoc': totalVoc,
        if (gasResistance != null) 'gasResistance': gasResistance,
        'timestamp': timestamp.toIso8601String(),
        if (annotation != null) 'annotation': annotation,
        if (location != null) 'location': location!.toJson,
        if (mode != null) 'mode': mode!.name,
      };

  @override
  FlattenedDataPoint.fromJson(Map<String, dynamic> json)
      : pm1 = json['pm1'],
        pm25 = json['pm25'],
        pm4 = json['pm4'],
        pm10 = json['pm10'],
        humidity = json['humidity'],
        temperature = json['temperature'],
        voc = json['voc'],
        nox = json['nox'],
        pressure = json['pressure'],
        co2 = json['co2'],
        o3 = json['o3'],
        aqi = json['aqi']?.round(),
        totalVoc = json['totalVoc'],
        gasResistance = json['gasResistance'],
        timestamp = DateTime.parse(json['timestamp']),
        annotation = json['annotation'],
        location = LatLngWithPrecision.fromJson(json['location']),
        mode = json['mode'] != null ? MobilityModes.fromName(json['mode']) : null,
        super(sensor: LDSensor.all, values: {
          if (json['pm1'] != null) MeasurableQuantity.pm1: json['pm1'],
          if (json['pm25'] != null) MeasurableQuantity.pm25: json['pm25'],
          if (json['pm4'] != null) MeasurableQuantity.pm4: json['pm4'],
          if (json['pm10'] != null) MeasurableQuantity.pm10: json['pm10'],
          if (json['humidity'] != null) MeasurableQuantity.humidity: json['humidity'],
          if (json['temperature'] != null) MeasurableQuantity.temperature: json['temperature'],
          if (json['voc'] != null) MeasurableQuantity.voc: json['voc'],
          if (json['nox'] != null) MeasurableQuantity.nox: json['nox'],
          if (json['pressure'] != null) MeasurableQuantity.pressure: json['pressure'],
          if (json['co2'] != null) MeasurableQuantity.co2: json['co2'],
          if (json['o3'] != null) MeasurableQuantity.o3: json['o3'],
          if (json['aqi'] != null) MeasurableQuantity.aqi: json['aqi'].toDouble(),
          if (json['totalVoc'] != null) MeasurableQuantity.totalVoc: json['totalVoc'],
          if (json['gasResistance'] != null)
            MeasurableQuantity.gasResistance: json['gasResistance'],
        });

  bool isPmElevated() {
    if (pm1 != null && pm1! > MeasurableQuantity.pm1.elevatedLimit) return true;
    if (pm25 != null && pm25! > MeasurableQuantity.pm25.elevatedLimit) return true;
    if (pm4 != null && pm4! > MeasurableQuantity.pm4.elevatedLimit) return true;
    if (pm10 != null && pm10! > MeasurableQuantity.pm10.elevatedLimit) return true;
    return false;
  }

  bool isPmHigh() {
    if (pm1 != null && pm1! > MeasurableQuantity.pm1.highLimit) return true;
    if (pm25 != null && pm25! > MeasurableQuantity.pm25.highLimit) return true;
    if (pm4 != null && pm4! > MeasurableQuantity.pm4.highLimit) return true;
    if (pm10 != null && pm10! > MeasurableQuantity.pm10.highLimit) return true;
    return false;
  }

  factory FlattenedDataPoint.fromCsv(String csv) {
    List<String> parts = csv.split(',');
    bool includeMode = parts.length > 12;
    return FlattenedDataPoint(
      timestamp: DateTime.parse(parts[0]),
      pm1: parts[1].isNotEmpty ? double.parse(parts[1]) : null,
      pm25: parts[2].isNotEmpty ? double.parse(parts[2]) : null,
      pm4: parts[3].isNotEmpty ? double.parse(parts[3]) : null,
      pm10: parts[4].isNotEmpty ? double.parse(parts[4]) : null,
      humidity: parts[5].isNotEmpty ? double.parse(parts[5]) : null,
      temperature: parts[6].isNotEmpty ? double.parse(parts[6]) : null,
      voc: parts[7].isNotEmpty ? double.parse(parts[7]) : null,
      nox: parts[8].isNotEmpty ? double.parse(parts[8]) : null,
      pressure: parts[9].isNotEmpty ? double.parse(parts[9]) : null,
      location: parts[10].isNotEmpty && parts[11].isNotEmpty
          ? LatLngWithPrecision(double.parse(parts[10]), double.parse(parts[11]), null)
          : null,
      mode: includeMode ? (parts[12].isNotEmpty ? MobilityModes.fromName(parts[12]) : null) : null,
      annotation: parts[includeMode ? 13 : 12].isNotEmpty ? parts[includeMode ? 13 : 12] : null,
    );
  }
}

class FormattedValue {
  final String entry, value;
  final Color color;

  const FormattedValue({required this.entry, required this.value, required this.color});

  factory FormattedValue.from(MeasurableQuantity dimension, double amount) {
    String value;
    switch (dimension) {
      case MeasurableQuantity.pm01:
        value = 'PM0.1';
        break;
      case MeasurableQuantity.pm1:
        value = 'PM1.0';
        break;
      case MeasurableQuantity.pm25:
        value = 'PM2.5';
        break;
      case MeasurableQuantity.pm4:
        value = 'PM4.0';
        break;
      case MeasurableQuantity.pm10:
        value = 'PM10.0';
        break;
      case MeasurableQuantity.humidity:
        value = 'Hum';
        break;
      case MeasurableQuantity.temperature:
        value = 'Temp';
        break;
      case MeasurableQuantity.voc:
        value = 'VOC';
        break;
      case MeasurableQuantity.nox:
        value = 'NOx';
        break;
      case MeasurableQuantity.pressure:
        value = 'Pres';
        break;
      case MeasurableQuantity.co2:
        value = 'CO2';
        break;
      case MeasurableQuantity.o3:
        value = 'O3';
        break;
      case MeasurableQuantity.aqi:
        value = 'AQI';
        break;
      case MeasurableQuantity.gasResistance:
        value = 'Gas';
        break;
      case MeasurableQuantity.totalVoc:
        value = 'tVOC';
        break;
      case MeasurableQuantity.no2:
        value = 'NO2';
        break;
      case MeasurableQuantity.sgp40RawGasIndex:
        value = 'Gas Raw';
        break;
      case MeasurableQuantity.sgp40AdjustedGasIndex:
        value = 'Gas Adj';
        break;
      default:
        value = 'Unknown';
        break;
    }
    Color color;
    if (amount > dimension.highLimit) {
      color = Colors.red;
    } else if (amount > dimension.elevatedLimit) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }
    return FormattedValue(
      entry: value,
      value: amount.toStringAsFixed(1),
      color: color,
    );
  }

  static List<FormattedValue> fromDataPoint(MeasuredDataPoint dataPoint) {
    return dataPoint.flatten.values
        .map((key, value) => MapEntry(key, FormattedValue.from(key, value)))
        .values
        .toList();
  }
}

enum MobilityModes {
  walking,
  cycling,
  transit,
  driving;

  factory MobilityModes.fromName(String name) =>
      MobilityModes.values.firstWhere((e) => e.name == name);

  String get name => toString().split('.').last;
}
