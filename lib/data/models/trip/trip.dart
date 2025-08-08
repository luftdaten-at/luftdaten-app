import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:luftdaten.at/controller/device_info.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/model/ble_device.dart';
import 'package:luftdaten.at/model/chip_id.dart';
import 'package:luftdaten.at/model/sensor_details.dart';
import 'package:path_provider/path_provider.dart';

import 'measured_data.dart';

/// Multiple trips can be recorded at the same time. Each trip corresponds to one device and
/// can only be continued from that device. Trips loaded from storage can't be continued
/// (but maybe there should be a feature to display multiple trips on the map)
class Trip extends ChangeNotifier {
  List<MeasuredDataPoint> _data = [];
  final String? deviceDisplayName;
  final String? deviceFourLetterCode;
  final ChipId deviceChipId;
  final LDDeviceModel deviceModel;

  List<SensorDetails>? sensorDetails;

  bool isImported = false;

  Trip({
    required this.deviceDisplayName,
    required this.deviceFourLetterCode,
    required this.deviceChipId,
    required this.deviceModel,
    this.sensorDetails,
  });

  Trip.withData({
    required this.deviceDisplayName,
    required this.deviceFourLetterCode,
    required this.deviceModel,
    required this.deviceChipId,
    required List<MeasuredDataPoint> data,
    this.sensorDetails,
  }) : _data = data;

  set data(List<MeasuredDataPoint> value) {
    _data = value;
    notifyListeners();
  }

  List<MeasuredDataPoint> get data => _data;

  void addDataPoint(MeasuredDataPoint dataPoint) {
    _data.add(dataPoint);
    notifyListeners();
  }

  DateTime? get start => data.firstOrNull?.timestamp;

  DateTime? get end => data.lastOrNull?.timestamp;

  Duration? get length => start?.difference(end!);

  // Serialization and de-serialization
  Map<String, dynamic> toJson() {
    return {
      'version': 'Luftdaten.at JSON Trip v1.1',
      'device': {
        'displayName': deviceDisplayName,
        'fourLetterCode': deviceFourLetterCode,
        'chipId': deviceChipId.toJson(),
        'modelCode': deviceModel.id,
        'modelName': deviceModel.name,
        if (sensorDetails != null) 'sensors': sensorDetails!.map((e) => e.toJson()).toList(),
      },
      'platform': {
        'appVersion': appVersion,
        'appBuildNumber': buildNumber,
        'mobileDevice': DeviceInfo.summaryString,
      },
      'data': data.map((e) => e.toJson()).toList(),
    };
  }

  Trip.fromJson(Map<String, dynamic> json)
      : deviceDisplayName = json['device']['displayName'] ?? json['deviceDisplayName'],
        deviceFourLetterCode = json['device']['fourLetterCode'] ?? json['deviceFourLetterCode'],
        deviceChipId = (json['device']['chipId'] != null)
            ? ChipId.fromJson((json['device']['chipId'] as Map).cast<String, dynamic>())
            : const ChipId.unknown(),
        deviceModel = LDDeviceModel.fromId(json['device']['modelCode'] ?? json['deviceModel']),
        sensorDetails = (json['device']['sensors'] as List?)
            ?.map((e) => SensorDetails.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        _data = (json['data'] as List).map((e) => MeasuredDataPoint.fromJson(e)).toList(),
        isImported = true;

  // File saving
  String get fileName => '$deviceDisplayName-${start?.toIso8601String()}.json';

  Future<void> save() async {
    if (data.isEmpty) return;
    Directory directory = await getApplicationDocumentsDirectory();
    Directory tripsDirectory = await Directory('${directory.path}/trips').create(recursive: true);
    File file = File('${tripsDirectory.path}/$fileName');
    await file.writeAsString(json.encode(toJson()));
  }

  // CSV helpers
  Future<String> toCsv() async {
    List<String> lines = [];
    lines.add('# Luftdaten.at CSV v2.0');
    lines.add('# Timestamp, Latitude, Longitude, Sensor, Dimension, Unit, Value');
    lines.add('# Device: $deviceFourLetterCode (${deviceModel.name}, ${deviceChipId.chipId})');
    lines.add('# App: $appVersion ($buildNumber)');
    lines.add('# Mobile device: ${DeviceInfo.summaryString}');
    lines.add('# Sensors:');
    if (sensorDetails != null) {
      for (SensorDetails sensor in sensorDetails!) {
        List<String> details = [
          if(sensor.serialNumber != null) 'Serial: ${sensor.serialNumber}',
          if(sensor.firmwareVersion != null) 'Firmware: ${sensor.firmwareVersion}',
          if(sensor.hardwareVersion != null) 'Hardware: ${sensor.hardwareVersion}',
          if(sensor.protocolVersion != null) 'Protocol: ${sensor.protocolVersion}',
        ];
        String detailsString = details.isNotEmpty ? ': (${details.join(', ')})' : '';
        lines.add('# ${sensor.model.name.toUpperCase()}$detailsString');
      }
    } else {
      lines.add('# No sensor details available');
    }
    for(MeasuredDataPoint dataPoint in data) {
      lines.addAll(dataPoint.toCsv());
    }
    return lines.join('\n');
  }

  factory Trip.fromCsv(String csv) {
    // TODO change to version 2.0
    List<String> lines = csv.split(',');
    if (lines[0] != '# Luftdaten.at CSV v1.0') {
      logger.d('Could not recognise CSV format, attempting to parse anyways');
    }
    List<MeasuredDataPoint> parsedData = [];
    for (String line in lines) {
      if (!line.startsWith('#')) {
        parsedData.add(MeasuredDataPoint.fromCsv(line));
      }
    }
    return Trip.withData(
      deviceDisplayName: 'Imported',
      deviceFourLetterCode: 'imtd',
      deviceChipId: const ChipId.unknown(),
      deviceModel: LDDeviceModel.unknownPortable,
      data: parsedData,
    )..isImported = true;
  }
}

class InvalidCsvException implements Exception {}
