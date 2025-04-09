import 'package:json_annotation/json_annotation.dart';

part 'sensor_data.g.dart';

@JsonSerializable()
class Location {
  Location(this.longitude, this.latitude, this.altitude);
  dynamic longitude;
  dynamic latitude;
  dynamic altitude;

  factory Location.fromJson(Map<dynamic, dynamic> json) => _$LocationFromJson(json);
  Map<dynamic, dynamic> toJson() => _$LocationToJson(this);
}

@JsonSerializable()
class SensorDataValue {
  dynamic id;
  String value_type;
  dynamic value;
  SensorDataValue(this.id, this.value_type, this.value);
  factory SensorDataValue.fromJson(Map<dynamic, dynamic> json) => _$SensorDataValueFromJson(json);
  Map<dynamic, dynamic> toJson() => _$SensorDataValueToJson(this);

}


@JsonSerializable()
class SensorType {
  dynamic id;
  String manufacturer;
  String name;
  SensorType(this.id, this.manufacturer, this.name);
  factory SensorType.fromJson(Map<dynamic, dynamic> json) => _$SensorTypeFromJson(json);
  Map<dynamic, dynamic> toJson() => _$SensorTypeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Sensor {
  dynamic id;
  SensorType sensor_type;
  Sensor(this.id, this.sensor_type);
  factory Sensor.fromJson(Map<dynamic, dynamic> json) => _$SensorFromJson(json);
  Map<dynamic, dynamic> toJson() => _$SensorToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SCData {
  Location location;
  List<SensorDataValue> sensordatavalues;
  Sensor sensor;
  DateTime timestamp;
  SCData(this.timestamp, this.location, this.sensordatavalues, this.sensor);
  factory SCData.fromJson(Map<dynamic, dynamic> json) => _$SCDataFromJson(json);
  Map<dynamic, dynamic> toJson() => _$SCDataToJson(this);
}
