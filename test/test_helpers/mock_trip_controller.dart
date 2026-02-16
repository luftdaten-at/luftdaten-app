import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';

class MockTripController extends TripController {
  @override
  Future<void> init() async {
    ongoingTrips = {
      BleDevice.unknown(): Trip(
        deviceDisplayName: null,
        deviceFourLetterCode: null,
        deviceChipId: const ChipId.unknown(),
        deviceModel: LDDeviceModel.unknownPortable,
      )
        ..addDataPoint(MeasuredDataPoint(
          timestamp: DateTime.now().subtract(const Duration(days: 20, hours: 2)),
          sensorData: [
            FlattenedDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 20)), pm1: 5)
          ],
        ))
        ..addDataPoint(MeasuredDataPoint(
          timestamp: DateTime.now().subtract(const Duration(days: 20)),
          sensorData: [
            FlattenedDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 20)), pm1: 5)
          ],
        )),
      BleDevice.unknown(): Trip(
        deviceDisplayName: null,
        deviceFourLetterCode: null,
        deviceChipId: const ChipId.unknown(),
        deviceModel: LDDeviceModel.unknownPortable,
      )
        ..addDataPoint(MeasuredDataPoint(
          timestamp: DateTime.now().subtract(const Duration(days: 5, minutes: 4)),
          sensorData: [
            FlattenedDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 20)), pm1: 5)
          ],
        ))
        ..addDataPoint(MeasuredDataPoint(
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          sensorData: [
            FlattenedDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 20)), pm1: 5)
          ],
        )),
    };
  }
}
