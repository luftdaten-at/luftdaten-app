import 'package:flutter/cupertino.dart';
import 'package:luftdaten.at/core/background_service.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/model/ble_device.dart';
import 'package:luftdaten.at/model/chip_id.dart';
import 'package:luftdaten.at/features/measurement/models/measured_data.dart';
import 'package:luftdaten.at/features/measurement/models/trip.dart';

class TripController extends ChangeNotifier {
  TripController();

  /// Trips that have been started this session and are currently still displayed.
  /// If we are currently measuring, measurements will be added to these trips.
  Map<BleDevice, Trip> ongoingTrips = {};

  /// Trips that have been loaded from storage or imported from other files
  List<Trip> loadedTrips = [];

  /// Current mode of transport
  MobilityModes _mobilityMode = MobilityModes.walking;

  MobilityModes get mobilityMode => _mobilityMode;

  set mobilityMode(MobilityModes mode) {
    _mobilityMode = mode;
    notifyListeners();
  }

  bool isOngoing = false;
  DateTime? currentTripStartedAt;

  Future<void> init() async {
    // TODO what do we actually need to initialise?
  }

  void reset() {
    ongoingTrips = {};
    loadedTrips = [];
    notifyListeners();
  }

  /// If ongoing trips have not been cleared before starting, and device list matches that ongoing
  /// list, will continue those trips
  void startTrip(List<BleDevice> devices) {
    if (ongoingTrips.keys.every((e) => devices.contains(e)) &&
        devices.every((e) => ongoingTrips.keys.contains(e))) {
      // Continue trips
      logger.d('Continuing existing trips');
    } else {
      // Create new trips
      for (BleDevice device in devices) {
        ongoingTrips[device] = Trip(
          deviceDisplayName: device.displayName,
          deviceFourLetterCode: device.fourLetterCode,
          deviceModel: device.model,
          deviceChipId: ChipId.fromMac(device.bleMacAddress),
          sensorDetails: device.availableSensors,
        )..addListener(() => notifyListeners());
      }
      logger.d('Created ${ongoingTrips.length} new trips');
    }
    isOngoing = true;
    currentTripStartedAt = DateTime.now();
    _mobilityMode = MobilityModes.walking;
    notifyListeners();
    getIt<BackgroundService>()
        .startTrip(devices.map((e) => e.measurementInterval).toList().smallest);
  }

  void stopTrip() {
    getIt<BackgroundService>().stopTrip();
    for(Trip trip in ongoingTrips.values) {
      trip.save();
    }
    isOngoing = false;
    currentTripStartedAt = null;
    notifyListeners();
  }

  Trip? get primaryTripToDisplay => ongoingTrips.values.firstOrNull ?? loadedTrips.firstOrNull;

  void clear() {
    ongoingTrips.forEach((key, value) => value.save());
    ongoingTrips = {};
    loadedTrips = [];
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

extension _Smallest on List<int> {
  int get smallest {
    int num = this[0];
    for (int val in this) {
      if (val < num) {
        num = val;
      }
    }
    return num;
  }
}
