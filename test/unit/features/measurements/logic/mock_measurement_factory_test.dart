import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_devices.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_factory.dart';

void main() {
  group('MockMeasurementFactory', () {
    test('goodAir preset has 15 points with low PM2.5', () {
      final trip = MockMeasurementFactory.buildPreset(MockMeasurementPreset.goodAir);
      expect(trip.deviceFourLetterCode, MockMeasurementDevices.mockFourLetterCode);
      expect(trip.isImported, isTrue);
      expect(trip.data.length, 15);
      for (final point in trip.data) {
        expect(point.location, isNotNull);
        final pm25 = point.flatten.pm25;
        expect(pm25, isNotNull);
        expect(pm25!, greaterThanOrEqualTo(8));
        expect(pm25, lessThanOrEqualTo(16));
      }
    });

    test('badAir preset has 12 points with high PM2.5', () {
      final trip = MockMeasurementFactory.buildPreset(MockMeasurementPreset.badAir);
      expect(trip.data.length, 12);
      for (final point in trip.data) {
        expect(point.location, isNotNull);
        final pm25 = point.flatten.pm25!;
        expect(pm25, greaterThanOrEqualTo(60));
        expect(pm25, lessThanOrEqualTo(125));
      }
    });

    test('mapGradient preset has 25 points ramping PM2.5', () {
      final trip = MockMeasurementFactory.buildPreset(MockMeasurementPreset.mapGradient);
      expect(trip.data.length, 25);
      final first = trip.data.first.flatten.pm25!;
      final last = trip.data.last.flatten.pm25!;
      expect(first, closeTo(5, 1));
      expect(last, closeTo(80, 2));
      expect(last, greaterThan(first));
    });

    test('successive presets use different path origins', () {
      final a = MockMeasurementFactory.buildPreset(MockMeasurementPreset.goodAir);
      final b = MockMeasurementFactory.buildPreset(MockMeasurementPreset.goodAir);
      expect(a.data.first.location!.latitude, isNot(b.data.first.location!.latitude));
    });
  });
}
