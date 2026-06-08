import 'dart:math';

import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';
import 'package:luftdaten.at/features/measurements/data/latlng_with_precision.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_devices.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_telemetry.dart';

enum MockMeasurementPreset {
  goodAir,
  badAir,
  mapGradient,
}

class MockMeasurementFactory {
  MockMeasurementFactory._();

  static const _defaultLat = 48.21919466912646;
  static const _defaultLon = 16.383482313924404;

  static int _trailOffset = 0;

  static Trip buildPreset(MockMeasurementPreset preset) {
    final (pointCount, pmBuilder) = switch (preset) {
      MockMeasurementPreset.goodAir => (
          15,
          (int i, int n) => 8.0 + (i / n) * 7.0,
        ),
      MockMeasurementPreset.badAir => (
          12,
          (int i, int n) => 60.0 + (i / n) * 60.0,
        ),
      MockMeasurementPreset.mapGradient => (
          25,
          (int i, int n) => 5.0 + (i / (n - 1)) * 75.0,
        ),
    };

    final origin = _nextOrigin();
    final points = <MeasuredDataPoint>[];
    final now = DateTime.now();

    for (var i = 0; i < pointCount; i++) {
      final pm25 = pmBuilder(i, pointCount);
      final location = _pointAlongPath(origin.$1, origin.$2, i, pointCount);
      points.add(
        MeasuredDataPoint(
          timestamp: now.subtract(Duration(minutes: pointCount - i)),
          location: location,
          mode: MobilityModes.walking,
          sensorData: [
            SensorDataPoint(
              sensor: LDSensor.sen5x,
              values: MockMeasurementTelemetry.valuesFromPm25(
                pm25,
                temp: 20 + sin(i / 3) * 2,
              ),
            ),
          ],
          j: const {'mock': true},
        ),
      );
    }

    return Trip.withData(
      deviceDisplayName: 'Mock-Messung',
      deviceFourLetterCode: MockMeasurementDevices.mockFourLetterCode,
      deviceChipId: const ChipId.unknown(),
      deviceModel: LDDeviceModel.aRound,
      data: points,
    )..isImported = true;
  }

  static Trip buildLiveTripShell() {
    return Trip(
      deviceDisplayName: 'Mock Live',
      deviceFourLetterCode: MockMeasurementDevices.mockFourLetterCode,
      deviceChipId: ChipId.fromChipId('mocklive0001'),
      deviceModel: LDDeviceModel.aRound,
    );
  }

  static (double lat, double lon) _nextOrigin() {
    final offset = _trailOffset++;
    const step = 0.002;
    return (
      _defaultLat + offset * step,
      _defaultLon + offset * step * 0.7,
    );
  }

  static LatLngWithPrecision _pointAlongPath(
    double originLat,
    double originLon,
    int index,
    int count,
  ) {
    const stepMeters = 14.0;
    const metersPerDegreeLat = 111320.0;
    final dLat = stepMeters / metersPerDegreeLat;
    final dLon =
        stepMeters / (metersPerDegreeLat * cos(originLat * pi / 180));
    final progress = count <= 1 ? 0.0 : index / (count - 1);
    final lat = originLat + dLat * progress * 1.2;
    final lon = originLon + dLon * progress;
    return LatLngWithPrecision(lat, lon, 8);
  }
}
