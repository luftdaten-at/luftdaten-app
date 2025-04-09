// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<dynamic, dynamic> json) => Location(
      json['longitude'],
      json['latitude'],
      json['altitude'],
    );

Map<dynamic, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'altitude': instance.altitude,
    };

SensorDataValue _$SensorDataValueFromJson(Map<dynamic, dynamic> json) =>
    SensorDataValue(
      json['id'],
      json['value_type'] as String,
      json['value'],
    );

Map<dynamic, dynamic> _$SensorDataValueToJson(SensorDataValue instance) =>
    <String, dynamic>{
      'id': instance.id,
      'value_type': instance.value_type,
      'value': instance.value,
    };

SensorType _$SensorTypeFromJson(Map<dynamic, dynamic> json) => SensorType(
      json['id'],
      json['manufacturer'] as String,
      json['name'] as String,
    );

Map<dynamic, dynamic> _$SensorTypeToJson(SensorType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'manufacturer': instance.manufacturer,
      'name': instance.name,
    };

Sensor _$SensorFromJson(Map<dynamic, dynamic> json) => Sensor(
      json['id'],
      SensorType.fromJson(json['sensor_type'] as Map<dynamic, dynamic>),
    );

Map<dynamic, dynamic> _$SensorToJson(Sensor instance) => <String, dynamic>{
      'id': instance.id,
      'sensor_type': instance.sensor_type.toJson(),
    };

SCData _$SCDataFromJson(Map<dynamic, dynamic> json) => SCData(
      DateTime.parse(json['timestamp'] as String),
      Location.fromJson(json['location'] as Map<dynamic, dynamic>),
      (json['sensordatavalues'] as List<dynamic>)
          .map((e) => SensorDataValue.fromJson(e as Map<dynamic, dynamic>))
          .toList(),
      Sensor.fromJson(json['sensor'] as Map<dynamic, dynamic>),
    );

Map<dynamic, dynamic> _$SCDataToJson(SCData instance) => <String, dynamic>{
      'location': instance.location.toJson(),
      'sensordatavalues':
          instance.sensordatavalues.map((e) => e.toJson()).toList(),
      'sensor': instance.sensor.toJson(),
      'timestamp': instance.timestamp.toIso8601String(),
    };
