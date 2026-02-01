// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      json['longitude'],
      json['latitude'],
      json['altitude'],
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'altitude': instance.altitude,
    };

SensorDataValue _$SensorDataValueFromJson(Map<String, dynamic> json) =>
    SensorDataValue(
      json['id'],
      json['value_type'] as String,
      json['value'],
    );

Map<String, dynamic> _$SensorDataValueToJson(SensorDataValue instance) =>
    <String, dynamic>{
      'id': instance.id,
      'value_type': instance.value_type,
      'value': instance.value,
    };

SensorType _$SensorTypeFromJson(Map<String, dynamic> json) => SensorType(
      json['id'],
      json['manufacturer'] as String,
      json['name'] as String,
    );

Map<String, dynamic> _$SensorTypeToJson(SensorType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'manufacturer': instance.manufacturer,
      'name': instance.name,
    };

Sensor _$SensorFromJson(Map<String, dynamic> json) => Sensor(
      json['id'],
      SensorType.fromJson(json['sensor_type'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SensorToJson(Sensor instance) => <String, dynamic>{
      'id': instance.id,
      'sensor_type': instance.sensor_type.toJson(),
    };

SCData _$SCDataFromJson(Map<String, dynamic> json) => SCData(
      DateTime.parse(json['timestamp'] as String),
      Location.fromJson(json['location'] as Map<String, dynamic>),
      (json['sensordatavalues'] as List<dynamic>)
          .map((e) => SensorDataValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      Sensor.fromJson(json['sensor'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SCDataToJson(SCData instance) => <String, dynamic>{
      'location': instance.location.toJson(),
      'sensordatavalues':
          instance.sensordatavalues.map((e) => e.toJson()).toList(),
      'sensor': instance.sensor.toJson(),
      'timestamp': instance.timestamp.toIso8601String(),
    };
