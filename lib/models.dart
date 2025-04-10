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
  double? value;

  Values(this.dimension, this.value);

  factory Values.fromJson(Map<String, dynamic> json) {
    return Values(
      json['dimension'],
      json['value'],
    );
  }
}

class Measurement {
  Location location;
  List<Values> values;
  String deviceId;
  DateTime? time;

  Measurement(this.location, this.values, this.deviceId, this.time);

  factory Measurement.fromJson(Map<String, dynamic> jsonData) {
    return Measurement(
      Location.fromJson(jsonData['location']),
      (jsonData['values'] as List).map((item) => Values.fromJson(item)).toList(),
      jsonData['device'],
      DateTime.tryParse(jsonData['time_measured']),
    );
  }

  double? get_valueByDimension(int dimension){ 
    return values.where((val) => val.dimension == dimension).firstOrNull?.value;
  }
}