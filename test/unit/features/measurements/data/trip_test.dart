import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/config/env.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';

void main() {
  setUp(() {
    appVersion = '1.0.0-test';
    buildNumber = '1';
  });

  group('Trip', () {
    test('addDataPoint increases data length', () {
      final trip = Trip(
        deviceDisplayName: 'Test',
        deviceFourLetterCode: 'TST1',
        deviceChipId: const ChipId.unknown(),
        deviceModel: LDDeviceModel.unknownPortable,
      );
      final dp = MeasuredDataPoint(
        timestamp: DateTime(2024, 3, 15),
        sensorData: [
          SensorDataPoint.fromJson({'sensor': 'sen5x', 'pm25': 10.0}),
        ],
      );
      trip.addDataPoint(dp);
      expect(trip.data.length, 1);
      expect(trip.data.first.timestamp, DateTime(2024, 3, 15));
    });

    test('start and end reflect first and last timestamp', () {
      final trip = Trip.withData(
        deviceDisplayName: 'Test',
        deviceFourLetterCode: 'TST1',
        deviceChipId: const ChipId.unknown(),
        deviceModel: LDDeviceModel.unknownPortable,
        data: [
          MeasuredDataPoint(
            timestamp: DateTime(2024, 3, 15, 10, 0),
            sensorData: [
              SensorDataPoint.fromJson({'sensor': 'sen5x', 'pm25': 5.0}),
            ],
          ),
          MeasuredDataPoint(
            timestamp: DateTime(2024, 3, 15, 11, 0),
            sensorData: [
              SensorDataPoint.fromJson({'sensor': 'sen5x', 'pm25': 8.0}),
            ],
          ),
        ],
      );
      expect(trip.start, DateTime(2024, 3, 15, 10, 0));
      expect(trip.end, DateTime(2024, 3, 15, 11, 0));
      expect(trip.length, const Duration(hours: -1));
    });

    test('fromJson parses device and data', () {
      final trip = Trip.fromJson({
        'device': {
          'displayName': 'MyDevice',
          'fourLetterCode': 'ABCD',
          'chipId': {'chipId': 'AABBCCDDEEFF', 'mac': '112233445566'},
          'modelCode': 1,
          'modelName': 'Air aRound',
        },
        'data': [
          {
            'timestamp': '2024-03-15T10:00:00.000',
            'sensorData': [
              {'sensor': 'sen5x', 'pm25': 12.5},
            ],
          },
        ],
      });
      expect(trip.deviceDisplayName, 'MyDevice');
      expect(trip.deviceFourLetterCode, 'ABCD');
      expect(trip.data.length, 1);
      expect(trip.isImported, isTrue);
    });

    test('fileName format', () {
      final trip = Trip.withData(
        deviceDisplayName: 'Device',
        deviceFourLetterCode: 'ABCD',
        deviceChipId: const ChipId.unknown(),
        deviceModel: LDDeviceModel.unknownPortable,
        data: [
          MeasuredDataPoint(
            timestamp: DateTime(2024, 3, 15, 10, 0),
            sensorData: [
              SensorDataPoint.fromJson({'sensor': 'sen5x', 'pm25': 5.0}),
            ],
          ),
        ],
      );
      expect(trip.fileName, startsWith('Device-'));
      expect(trip.fileName, endsWith('.json'));
    });
  });
}
