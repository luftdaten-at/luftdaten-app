import 'lib/presentation/controllers/trip/trip_controller.dart';
import 'lib/data/models/ble/ble_device.dart';
import 'lib/data/models/device/chip_id.dart';
import 'lib/data/models/measurement/measured_data.dart';
import 'lib/data/models/trip/trip.dart';

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
