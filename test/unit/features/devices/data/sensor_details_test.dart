import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  group('SensorDetails', () {
    test('toJson and fromJson roundtrip', () {
      final sd = SensorDetails(
        LDSensor.sen5x,
        serialNumber: 'SN123',
        firmwareVersion: '1.0',
      );
      final json = sd.toJson();
      final restored = SensorDetails.fromJson(json);
      expect(restored.model, LDSensor.sen5x);
      expect(restored.serialNumber, 'SN123');
      expect(restored.firmwareVersion, '1.0');
    });
  });
}
