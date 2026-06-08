import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_factory.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';

void main() {
  group('TripController mock helpers', () {
    late TripController controller;

    setUp(() {
      controller = TripController();
    });

    test('addMockLoadedTrip and clearMockTrips', () {
      final trip = MockMeasurementFactory.buildPreset(MockMeasurementPreset.goodAir);
      controller.addMockLoadedTrip(trip);
      expect(controller.mockLoadedTripCount, 1);
      expect(controller.hasMockTrips, isTrue);

      controller.clearMockTrips();
      expect(controller.mockLoadedTripCount, 0);
      expect(controller.hasMockTrips, isFalse);
    });

    test('clearMockTrips leaves non-mock loaded trips', () {
      final mockTrip =
          MockMeasurementFactory.buildPreset(MockMeasurementPreset.goodAir);
      final otherTrip = Trip.withData(
        deviceDisplayName: 'Imported',
        deviceFourLetterCode: 'real',
        deviceChipId: const ChipId.unknown(),
        deviceModel: LDDeviceModel.aRound,
        data: MockMeasurementFactory.buildPreset(MockMeasurementPreset.badAir).data,
      );
      controller
        ..addMockLoadedTrip(mockTrip)
        ..addMockLoadedTrip(otherTrip);

      controller.clearMockTrips();
      expect(controller.loadedTrips.length, 1);
      expect(controller.loadedTrips.first.deviceFourLetterCode, 'real');
    });
  });
}
