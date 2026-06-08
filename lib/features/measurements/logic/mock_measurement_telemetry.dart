import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/measurements/data/latlng_with_precision.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/mock_measurement_devices.dart';

/// Synthetic sensor readings for the debug live mock measurement loop.
class MockMeasurementTelemetry {
  MockMeasurementTelemetry._();

  static const _defaultLat = 48.21919466912646;
  static const _defaultLon = 16.383482313924404;

  static double _liveLat = _defaultLat;
  static double _liveLon = _defaultLon;
  static int _livePointIndex = 0;

  static void resetLivePath() {
    _liveLat = _defaultLat;
    _liveLon = _defaultLon;
    _livePointIndex = 0;
  }

  static List<dynamic> readSensorValues(
    BleDevice device, {
    Position? position,
  }) {
    if (!MockMeasurementDevices.isLiveMeasurementDevice(device)) {
      throw StateError('readSensorValues called on non-mock-live device');
    }

    if (position != null) {
      _liveLat = position.latitude;
      _liveLon = position.longitude;
    } else {
      _advanceSyntheticPosition();
    }
    _livePointIndex++;

    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final pm25 = 12 + 8 * sin(t / 30 + _livePointIndex * 0.2);
    final values = valuesFromPm25(pm25, temp: 21 + 2 * sin(t / 120));

    final dataPoints = [
      SensorDataPoint(sensor: LDSensor.sen5x, values: values),
    ];

    final metadata = <String, dynamic>{
      'chip_id': device.chipIdForApi,
      'mock': true,
      'mockLatitude': _liveLat,
      'mockLongitude': _liveLon,
    };

    return [dataPoints, metadata];
  }

  static void _advanceSyntheticPosition() {
    const stepMeters = 12.0;
    const metersPerDegreeLat = 111320.0;
    final dLat = stepMeters / metersPerDegreeLat;
    final dLon = stepMeters /
        (metersPerDegreeLat * cos(_liveLat * pi / 180));
    final angle = _livePointIndex * 0.35;
    _liveLat += dLat * cos(angle);
    _liveLon += dLon * sin(angle);
  }

  static Map<MeasurableQuantity, double> valuesFromPm25(
    double pm25, {
    required double temp,
  }) {
    final humidity = 45 + 5 * cos(pm25 / 20);
    return {
      MeasurableQuantity.pm25: pm25,
      MeasurableQuantity.pm10: pm25 * 1.2,
      MeasurableQuantity.pm1: pm25 * 0.8,
      MeasurableQuantity.pm4: pm25 * 1.1,
      MeasurableQuantity.temperature: temp,
      MeasurableQuantity.humidity: humidity,
      MeasurableQuantity.voc: 120 + 30 * sin(pm25 / 15),
    };
  }

  static LatLngWithPrecision? locationFromMetadata(Map<String, dynamic> j) {
    final lat = j['mockLatitude'];
    final lon = j['mockLongitude'];
    if (lat is num && lon is num) {
      return LatLngWithPrecision(lat.toDouble(), lon.toDouble(), null);
    }
    return null;
  }
}
