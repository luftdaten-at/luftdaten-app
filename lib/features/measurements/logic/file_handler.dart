// TODO this class should handle listing saved files and their properties & the sharing of files
// including conversion to CSV

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/utils/day.dart';
import 'package:path_provider/path_provider.dart';

import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';

class FileHandler extends ChangeNotifier {
  static final FileHandler _instance = FileHandler._();

  FileHandler._();

  factory FileHandler() => _instance;

  late Directory applicationFilesDir;

  void init() async {
    applicationFilesDir = await getApplicationDocumentsDirectory();
  }

  Future<List<DateTime>> getDatesWithSavedTrips() async {
    Directory trips = Directory('${applicationFilesDir.path}/trips');
    await trips.create(recursive: true);
    List<FileSystemEntity> files = trips.listSync();
    logger.d(files.map((e) => e.path).join('\n'));
    return files
        .map((e) => DateTime.parse(e.path.split('/').last.split('-').sublist(1).join('').replaceAll('.json', '')))
        .toList();
  }

  Future<List<Trip>> getTripsForDay(DateTime dateTime) async {
    Directory tripDir = Directory('${applicationFilesDir.path}/trips');
    List<FileSystemEntity> files = tripDir.listSync();
    List<Trip> trips = [];
    for(FileSystemEntity file in files) {
      DateTime fileDate = DateTime.parse(file.path.split('/').last.split('-').sublist(1).join('-').replaceAll('.json', ''));
      if(fileDate.date == dateTime.date) {
        trips.add(Trip.fromJson(json.decode(File(file.path).readAsStringSync())));
      }
    }
    return trips;
  }
}
