import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';
import 'package:luftdaten.at/features/devices/logic/ble_sensor_info_parser.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  group('isBleSensorInfoStub', () {
    test('detects badge firmware placeholder', () {
      expect(isBleSensorInfoStub(const [0x06]), isTrue);
      expect(isBleSensorInfoStub(const []), isTrue);
      expect(isBleSensorInfoStub([LDSensor.shtc3.id, 0xFF]), isFalse);
    });
  });

  group('parseSensorsFromDeviceInfoJson', () {
    test('parses firmware model_id entries', () {
      final sensors = parseSensorsFromDeviceInfoJson({
        'sensor_list': [
          {'model_id': LDSensor.shtc3.id, 'serial_number': 'ABC'},
          {'model_id': LDSensor.as7331.id, 'serial_number': ''},
        ],
      });

      expect(sensors, hasLength(2));
      expect(sensors[0].model, LDSensor.shtc3);
      expect(sensors[0].serialNumber, 'ABC');
      expect(sensors[1].model, LDSensor.as7331);
    });

    test('parses mock model/serial keys', () {
      final sensors = parseSensorsFromDeviceInfoJson({
        'sensor_list': [
          {'model': LDSensor.sen5x.id, 'serial': 'MOCK-SEN5X'},
        ],
      });

      expect(sensors, hasLength(1));
      expect(sensors.first.model, LDSensor.sen5x);
      expect(sensors.first.serialNumber, 'MOCK-SEN5X');
    });
  });

  group('parseSensorsFromDeviceInfoBinary', () {
    test('parses connected sensor block from byte 9', () {
      final raw = List<int>.filled(14, 0)
        ..[9] = 2
        ..[10] = LDSensor.shtc3.id
        ..[11] = 0x01
        ..[12] = LDSensor.as7331.id
        ..[13] = 0x01;

      final sensors = parseSensorsFromDeviceInfoBinary(raw);
      expect(sensors.map((s) => s.model), [LDSensor.shtc3, LDSensor.as7331]);
    });

    test('skips sensors with zero status', () {
      final raw = List<int>.filled(12, 0)
        ..[9] = 1
        ..[10] = LDSensor.shtc3.id
        ..[11] = 0;

      expect(parseSensorsFromDeviceInfoBinary(raw), isEmpty);
    });
  });

  group('parseSensorsFromSensorInfoCharacteristic', () {
    test('returns empty for stub byte', () {
      expect(parseSensorsFromSensorInfoCharacteristic(const [0x06]), isEmpty);
    });

    test('parses split blocks with model id first byte', () {
      final raw = [
        LDSensor.shtc3.id,
        0xFF,
        0xFF,
        LDSensor.as7331.id,
        0xFF,
        0xFF,
      ];
      final sensors = parseSensorsFromSensorInfoCharacteristic(raw);
      expect(sensors.map((s) => s.model), [LDSensor.shtc3, LDSensor.as7331]);
    });
  });
}
