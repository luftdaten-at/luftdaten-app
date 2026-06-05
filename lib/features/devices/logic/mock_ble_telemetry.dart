import 'dart:math';

import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_profile.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

/// Fake sensor readings for mock BLE devices (trip / background loop).
class MockBleTelemetry {
  MockBleTelemetry._();

  static List<dynamic> readSensorValues(BleDevice device) {
    if (!MockBleDevices.canUseMockBle(device)) {
      throw StateError('readSensorValues called on non-mock device');
    }
    MockBleProfile.refreshStatus(device);

    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final pm25 = 12 + 8 * sin(t / 30);
    final pm10 = pm25 * 1.2;
    final temp = 21 + 2 * sin(t / 120);
    final humidity = 45 + 5 * cos(t / 90);

    final values = <MeasurableQuantity, double>{
      MeasurableQuantity.pm25: pm25,
      MeasurableQuantity.pm10: pm10,
      MeasurableQuantity.pm1: pm25 * 0.8,
      MeasurableQuantity.pm4: pm25 * 1.1,
      MeasurableQuantity.temperature: temp,
      MeasurableQuantity.humidity: humidity,
      MeasurableQuantity.voc: 120 + 30 * sin(t / 45),
    };

    final dataPoints = [
      SensorDataPoint(sensor: LDSensor.sen5x, values: values),
    ];

    final metadata = <String, dynamic>{
      'chip_id': device.chipIdForApi,
      'mock': true,
    };

    return [dataPoints, metadata];
  }
}
