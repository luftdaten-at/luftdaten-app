import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/device_error.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  group('DeviceError', () {
    test('SensorNotFoundError holds sensor', () {
      final error = SensorNotFoundError(LDSensor.sen5x);
      expect(error.sensor, LDSensor.sen5x);
      expect(error, isA<DeviceError>());
    });
  });
}
