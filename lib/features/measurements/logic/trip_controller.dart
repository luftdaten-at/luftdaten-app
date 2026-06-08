import 'package:flutter/cupertino.dart';
import 'package:luftdaten.at/core/background_services/background_service.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_devices.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_factory.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_telemetry.dart';

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

  bool get isMockLiveActive =>
      ongoingTrips.keys.any(MockMeasurementDevices.isLiveMeasurementDevice);

  bool get hasMockTrips =>
      loadedTrips.any(_isMockTrip) ||
      ongoingTrips.values.any(_isMockTrip);

  int get mockLoadedTripCount =>
      loadedTrips.where(_isMockTrip).length;

  static bool _isMockTrip(Trip trip) =>
      MockMeasurementDevices.isMockTripDevice(trip.deviceFourLetterCode);

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
          deviceChipId: ChipId.fromChipId(device.chipIdForApi),
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
    for (Trip trip in ongoingTrips.values) {
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

  void addMockLoadedTrip(Trip trip) {
    loadedTrips.add(trip);
    notifyListeners();
  }

  void clearMockTrips() {
    if (isMockLiveActive) {
      stopMockLiveMeasurement();
    }
    loadedTrips.removeWhere(_isMockTrip);
    notifyListeners();
  }

  void startMockLiveMeasurement() {
    if (isOngoing) {
      logger.d('Mock live measurement: trip already ongoing');
      return;
    }
    MockMeasurementTelemetry.resetLivePath();
    final device = MockMeasurementDevices.liveMeasurement;
    ongoingTrips = {
      device: MockMeasurementFactory.buildLiveTripShell()
        ..addListener(() => notifyListeners()),
    };
    isOngoing = true;
    currentTripStartedAt = DateTime.now();
    _mobilityMode = MobilityModes.walking;
    notifyListeners();
    getIt<BackgroundService>().startTrip(device.measurementInterval);
  }

  void stopMockLiveMeasurement() {
    if (!isMockLiveActive) return;
    getIt<BackgroundService>().stopTrip();
    ongoingTrips.removeWhere(
      (device, _) => MockMeasurementDevices.isLiveMeasurementDevice(device),
    );
    if (ongoingTrips.isEmpty) {
      isOngoing = false;
      currentTripStartedAt = null;
    }
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
