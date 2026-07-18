import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_meas_log_parser.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
