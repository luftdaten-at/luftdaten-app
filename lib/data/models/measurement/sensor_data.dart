import 'package:json_annotation/json_annotation.dart';

part 'sensor_data.g.dart';

@JsonSerializable()
class Location {
  Location(this.longitude, this.latitude, this.altitude);
  dynamic longitude;
  dynamic latitude;
  dynamic altitude;

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}

@JsonSerializable()
class SensorDataValue {
  dynamic id;
  String valueType;
  dynamic value;
  SensorDataValue(this.id, this.valueType, this.value);
  factory SensorDataValue.fromJson(Map<String, dynamic> json) => _$SensorDataValueFromJson(json);
  Map<String, dynamic> toJson() => _$SensorDataValueToJson(this);

}


@JsonSerializable()
class SensorType {
  dynamic id;
  String manufacturer;
  String name;
  SensorType(this.id, this.manufacturer, this.name);
  factory SensorType.fromJson(Map<String, dynamic> json) => _$SensorTypeFromJson(json);
  Map<String, dynamic> toJson() => _$SensorTypeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Sensor {
  dynamic id;
  SensorType sensorType;
  Sensor(this.id, this.sensorType);
  factory Sensor.fromJson(Map<String, dynamic> json) => _$SensorFromJson(json);
  Map<String, dynamic> toJson() => _$SensorToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SCData {
  Location location;
  List<SensorDataValue> sensordatavalues;
  Sensor sensor;
  DateTime timestamp;
  SCData(this.timestamp, this.location, this.sensordatavalues, this.sensor);
  factory SCData.fromJson(Map<String, dynamic> json) => _$SCDataFromJson(json);
  Map<String, dynamic> toJson() => _$SCDataToJson(this);
}
