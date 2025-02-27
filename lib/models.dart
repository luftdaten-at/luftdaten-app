import 'dart:convert';

class Location {
  double lat;
  double lon;
  double? height;

  Location(this.lat, this.lon, this.height);

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      json['lat'],
      json['lon'],
      json['height'],
    );
  }
}

class Values {
  int dimension;
  double value;

  Values(this.dimension, this.value);

  factory Values.fromJson(Map<String, dynamic> json) {
    return Values(
      json['dimension'],
      json['value'],
    );
  }
}

class Measurement {
  Location? location;
  int? sensorModel;
  List<Values> values;
  String device;
  DateTime? time;

  Measurement(this.location, this.sensorModel, this.values, this.device, this.time);

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      json['location'] != null ? Location.fromJson(json['location']) : null,
      json['sensorModel'],
      (json['values'] as List).map((v) => Values.fromJson(v)).toList(),
      json['device'],
      json['time'] != null ? DateTime.parse(json['time']) : null,
    );
  }
}

Measurement loadMeasurementFromJson(Map<String, dynamic> jsonData) {
  var coordinates = jsonData['geometry']['coordinates'];
  var properties = jsonData['properties'];
  var sensor = properties['sensors'][0];

  Location location = Location(
      coordinates[1], coordinates[0], properties['height']);
  return Measurement(
      location,
      sensor['sensor_model'],
      (sensor['values'] as List)
          .map((v) => Values.fromJson(v))
          .toList(),
      properties['device'],
      properties['time'] != null ? DateTime.parse(properties['time']) : null);
}
