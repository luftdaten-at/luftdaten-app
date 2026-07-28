import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/config/env.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';
import 'package:luftdaten.at/features/measurements/data/environment_context_reading.dart';
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

  group('Trip indoor/outdoor classification', () {
    /// Overcast outdoor signature from the classification design document.
    MeasuredDataPoint outdoorPoint(DateTime timestamp) {
      return MeasuredDataPoint(
        timestamp: timestamp,
        sensorData: [
          SensorDataPoint(
            sensor: LDSensor.tsl2591,
            values: {
              MeasurableQuantity.lux: 10000,
              MeasurableQuantity.infrared: 3600,
              MeasurableQuantity.fullSpectrum: 10000,
            },
          ),
          SensorDataPoint(
            sensor: LDSensor.as7331,
            values: {
              MeasurableQuantity.uva: 700,
              MeasurableQuantity.uvb: 21,
            },
          ),
        ],
      );
    }

    Trip emptyTrip() => Trip(
          deviceDisplayName: 'Badge',
          deviceFourLetterCode: 'BDG1',
          deviceChipId: const ChipId.unknown(),
          deviceModel: LDDeviceModel.unknownPortable,
        );

    Trip recordedTrip({int count = 5}) {
      final trip = emptyTrip();
      final start = DateTime(2026, 1, 1, 12);
      for (var i = 0; i < count; i++) {
        trip.addDataPoint(outdoorPoint(start.add(Duration(seconds: 30 * i))));
      }
      return trip;
    }

    // Trip.toJson pulls in platform metadata that is not available under test,
    // so the file body is assembled from the data points directly.
    Map<String, dynamic> tripJson(Trip trip) => {
          'device': {
            'displayName': trip.deviceDisplayName,
            'fourLetterCode': trip.deviceFourLetterCode,
            'modelCode': trip.deviceModel.id,
          },
          'data': trip.data.map((e) => e.toJson()).toList(),
        };

    test('recorded measurements carry the classification', () {
      final trip = recordedTrip();

      expect(trip.data.every((e) => e.environment != null), isTrue);
      expect(trip.data.last.environment!.state, EnvironmentContextState.outdoor);
    });

    test('the classification survives a save and load cycle', () {
      final trip = recordedTrip();

      final restored = Trip.fromJson(tripJson(trip));

      expect(
        restored.data.map((e) => e.environment!.state),
        trip.data.map((e) => e.environment!.state),
      );
      expect(
        restored.data.last.environment!.score,
        trip.data.last.environment!.score,
      );
    });

    test('trips recorded before the classification existed get one on load', () {
      final legacyJson = tripJson(recordedTrip());
      for (final point in legacyJson['data'] as List) {
        (point as Map).remove('environment');
      }

      final restored = Trip.fromJson(legacyJson);

      expect(restored.data.last.environment!.state, EnvironmentContextState.outdoor);
    });

    test('measurements without light and UV sensors stay unclassified', () {
      final trip = emptyTrip();
      trip.addDataPoint(MeasuredDataPoint(
        timestamp: DateTime(2026, 1, 1, 12),
        sensorData: [
          SensorDataPoint(
            sensor: LDSensor.sen5x,
            values: {MeasurableQuantity.pm25: 8},
          ),
        ],
      ));

      expect(trip.data.single.environment, isNull);
      expect(trip.data.single.toJson().containsKey('environment'), isFalse);
    });

    test('bulk imported data is classified too', () {
      final start = DateTime(2026, 1, 1, 12);
      final trip = Trip.withData(
        deviceDisplayName: 'Badge',
        deviceFourLetterCode: 'BDG1',
        deviceChipId: const ChipId.unknown(),
        deviceModel: LDDeviceModel.unknownPortable,
        data: [
          for (var i = 0; i < 5; i++) outdoorPoint(start.add(Duration(seconds: 30 * i))),
        ],
      );

      expect(trip.data.last.environment!.state, EnvironmentContextState.outdoor);
    });
  });
}
