import 'package:luftdaten.at/features/devices/data/ble_device.dart';

/// Debug-only identifiers for synthetic measurement trips.
class MockMeasurementDevices {
  MockMeasurementDevices._();

  static const String liveBleId = 'mock:measurement-live';
  static const String mockFourLetterCode = 'mock';

  static final BleDevice liveMeasurement = BleDevice(
    model: LDDeviceModel.aRound,
    bleName: 'MOCK',
    bleMacAddress: '00:00:00:00:00:00',
    deviceOriginalDisplayName: 'Mock Live',
    bleId: liveBleId,
    isMock: true,
    measurementInterval: 10,
  );

  static bool isMockTripDevice(String? fourLetterCode) =>
      fourLetterCode == mockFourLetterCode;

  static bool isLiveMeasurementDevice(BleDevice device) =>
      device.bleId == liveBleId;
}
