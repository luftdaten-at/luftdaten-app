import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';
import 'package:luftdaten.at/controller/trip_controller.dart';
import 'package:luftdaten.at/model/workshop_configuration.dart';

import '../main.dart';
import '../model/measured_data.dart';
import '../model/trip.dart';
import 'app_settings.dart';

class WorkshopController extends ChangeNotifier {
  WorkshopConfiguration? _currentWorkshop;

  WorkshopConfiguration? get currentWorkshop => _currentWorkshop;

  DateTime? lastSent;

  set currentWorkshop(WorkshopConfiguration? value) {
    _currentWorkshop = value;
    if (value != null) {
      _box.write('current', value.toJson());
      periodicallyCheckStatus();
    } else {
      _box.remove('current');
    }
    notifyListeners();
  }

  final GetStorage _box = GetStorage('workshop');

  Future<void> init() async {
    await GetStorage.init('workshop');
    if (_box.hasData('current')) {
      logger.d('Loading current workshop from storage');
      currentWorkshop = WorkshopConfiguration.fromJson(_box.read('current'));
      checkIfWorkshopHasEnded();
    }
    notifyListeners();
  }

  String get serverUrl => AppSettings.I.useStagingServer ? 'staging.datahub.luftdaten.at' : 'datahub.luftdaten.at';

  void checkIfWorkshopHasEnded() {
    if (currentWorkshop != null && currentWorkshop!.end.toUtc().isBefore(DateTime.now().toUtc())) {
      exitWorkshop();
    }
  }

  void exitWorkshop() {
    currentWorkshop = null;
  }

  void attemptSendData() async {
    if (currentWorkshop == null) return;
    TripController tripController = getIt<TripController>();
    checkIfWorkshopHasEnded();
    if (currentWorkshop != null) {
      if (tripController.ongoingTrips.isEmpty) return;
      Trip trip = tripController.ongoingTrips.values.first;
      Iterable<FlattenedDataPoint> data;
      List<Map<String, dynamic>?> jsonList;
      if (lastSent == null) {
        data = trip.data.map((e) => e.flatten);
        jsonList = trip.data.map((e) => e.j).toList();
      } else {
        data = trip.data.where((e) => e.timestamp.isAfter(lastSent!)).map((e) => e.flatten);
        jsonList = trip.data.where((e) => e.timestamp.isAfter(lastSent!)).map((e) => e.j).toList();
        // Make sure we don't send too much data if any issues occur
        //if(data.length > 50) data = data.toList().sublist(data.length - 50);
      }
      data = data.where((e) => e.location != null);
      if (data.isEmpty) return;


      // Send data
      for(var j in jsonList){
          if(j == null) continue;
          j!["workshop"] = currentWorkshop?.id;
          logger.d('3.14159: $j');
          Response res = await post(
          Uri.parse('https://$serverUrl/api/v1/devices/data/'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(j)
          /* 
          json.encode(data
              .map((e) => {
                    "time": e.timestamp.toUtc().toIso8601String(),
                    if (e.pm1 != null) "pm1": e.pm1,
                    if (e.pm25 != null) "pm25": e.pm25,
                    if (e.pm10 != null) "pm10": e.pm10,
                    if (e.temperature != null) "temperature": e.temperature,
                    if (e.humidity != null) "humidity": e.humidity,
                    if (e.voc != null) "voc": e.voc,
                    if (e.nox != null) "nox": e.nox,
                    "device": trip.deviceChipId.chipId,
                    "workshop": currentWorkshop!.id.toLowerCase(),
                    if (e.location != null) "lat": e.location!.latitude,
                    if (e.location != null) "lon": e.location!.longitude,
                    if (e.location?.precision != null) "location_precision": e.location!.precision,
                    if (e.mode != null) "mode": e.mode!.name,
                    "participant": currentWorkshop!.participantUid,
                  })
              .toList()),
          */
        );
        logger.d('3.14159: statuscode: ${res.statusCode}');
        if (res.statusCode == 200) {
          // Data added successfully
          lastSent = DateTime.now();
          logger.d('Successfully sent ${data.length} workshop entries (HTTP 201)');
          logger.d('Will now only send items dated after ${lastSent!.toIso8601String()}');
          // If data was not added, retry on next attempt
        } else {
          logger.e('Failed to send workshop entries (HTTP ${res.statusCode}):');
          logger.e(res.body);
        }
      }
    }
  }

  Future<WorkshopConfiguration> loadWorkshopDetails(String id) async {
    id = id.toLowerCase();
    Response res;
    try {
      res = await get(Uri.parse('https://$serverUrl/api/workshop/detail/$id/'));
    } catch (_) {
      throw ConnectionError();
    }
    if (res.statusCode != 200) {
      throw InvalidIdError(id);
    }
    return WorkshopConfiguration.fromJson(json.decode(utf8.decode(res.bodyBytes)));
  }

  // We can check frequently, this function is inexpensive
  void periodicallyCheckStatus() async {
    if(_currentWorkshop == null) return;
    if(_currentWorkshop!.end.isBefore(DateTime.now().toUtc())) {
      exitWorkshop();
      return;
    }
    await Future.delayed(const Duration(seconds: 30));
  }
}

class ConnectionError extends Error {
  ConnectionError();
}

class InvalidIdError extends Error {
  final String id;

  InvalidIdError(this.id);
}

extension FormatAsWorkshopId on String {
  String get formatAsId => '${substring(0, 3).toUpperCase()}-${substring(3).toUpperCase()}';
}
