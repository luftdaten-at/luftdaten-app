import 'package:luftdaten.at/controller/trip_controller.dart';
import 'package:luftdaten.at/model/ble_device.dart';
import 'package:luftdaten.at/model/chip_id.dart';
import 'package:luftdaten.at/model/measured_data.dart';
import 'package:luftdaten.at/model/trip.dart';

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
