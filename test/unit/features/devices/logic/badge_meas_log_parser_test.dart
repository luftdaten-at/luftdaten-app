import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_meas_log_parser.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt_codec.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  setUpAll(initDeviceWidgetTestHarness);

  setUp(() async {
    await setUpDeviceWidgetTests(storageBucket: 'badge_meas_log_parser_tests');
  });

  tearDown(tearDownDeviceWidgetTests);

  group('BadgeMeasLogHeader', () {
    test('parses LDLG header from mock blob', () {
      final blob = MockBleGattCodec.encodeBadgeMeasLogBlob();
      final header = BadgeMeasLogHeader.parse(blob);
      expect(header, isNotNull);
      expect(header!.recordCount, 2);
      expect(header.recordSize, 48);
      expect(header.totalBytes, blob.length);
    });
  });

  group('badgeMeasLogEstimatedRecordTimes', () {
    test('returns chronologically ordered timestamps ending at endTime', () {
      final end = DateTime.utc(2026, 1, 1, 12, 1, 0);
      final times = badgeMeasLogEstimatedRecordTimes(recordCount: 3, endTime: end);

      expect(times, hasLength(3));
      expect(times.last, end);
      expect(times.first, end.subtract(const Duration(seconds: 60)));
    });
  });

  group('parseBadgeMeasLogToDatahubJson', () {
    late BleDevice device;

    setUp(() {
      device = BleDevice(
        model: LDDeviceModel.badge,
        bleName: 'Luftdaten.at-000000000010',
        bleMacAddress: '000000000010',
        deviceOriginalDisplayName: 'Mock Badge',
        isMock: true,
      )..firmwareVersion = const FirmwareVersion(1, 0, 0);
    });

    test('produces firmware-style lines with sensors', () {
      final blob = MockBleGattCodec.encodeBadgeMeasLogBlob();
      final result = parseBadgeMeasLogToDatahubJson(
        bytes: blob,
        device: device,
        importTime: DateTime.utc(2026, 1, 1, 12, 0, 0),
      );

      expect(result.ok, isTrue);
      expect(result.lines, hasLength(2));
      expect(result.lines.first['device'], isA<Map>());
      expect(result.lines.first['sensors'], isA<Map>());
      expect(result.lines.first['device']['model'], LDDeviceModel.badge.id);
    });

    test('rejects invalid magic', () {
      final blob = MockBleGattCodec.encodeBadgeMeasLogBlob();
      blob[0] = 0;
      final result = parseBadgeMeasLogToDatahubJson(bytes: blob, device: device);
      expect(result.ok, isFalse);
    });
  });

  group('badgeMeasLogLinesToTrip', () {
    late BleDevice device;

    setUp(() {
      device = BleDevice(
        model: LDDeviceModel.badge,
        bleName: 'Luftdaten.at-000000000010',
        bleMacAddress: '000000000010',
        deviceOriginalDisplayName: 'Mock Badge',
        isMock: true,
      )..firmwareVersion = const FirmwareVersion(1, 0, 0);
    });

    test('converts mock blob lines into trip with two data points', () {
      final blob = MockBleGattCodec.encodeBadgeMeasLogBlob();
      final parsed = parseBadgeMeasLogToDatahubJson(
        bytes: blob,
        device: device,
        importTime: DateTime.utc(2026, 1, 1, 12, 0, 0),
      );
      expect(parsed.ok, isTrue);

      final trip = badgeMeasLogLinesToTrip(lines: parsed.lines, device: device);
      expect(trip, isNotNull);
      expect(trip!.isImported, isTrue);
      expect(trip.data, hasLength(2));
      expect(trip.deviceModel, LDDeviceModel.badge);
      expect(trip.data.first.sensorData, isNotEmpty);
      expect(
        trip.data.first.sensorData.map((s) => s.sensor),
        containsAll([LDSensor.shtc3, LDSensor.bmv080, LDSensor.as7331]),
      );
    });
  });
}
