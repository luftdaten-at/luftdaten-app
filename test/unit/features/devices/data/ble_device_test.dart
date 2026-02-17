import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/chip_id.dart';

void main() {
  group('BleDevice', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'deviceBleName': 'Luftdaten.at-AABBCC-1',
        'bleMacAddress': 'AABBCCDDEEFF',
        'deviceOriginalName': 'Luftdaten.at-AABBCC-1',
        'modelName': 'Air aRound',
        'autoConnect': true,
        'measurementInterval': 300,
        'userAssignedName': 'My Device',
      };
      final device = BleDevice.fromJson(json);
      final restored = device.toJson();
      expect(restored['deviceBleName'], json['deviceBleName']);
      expect(restored['bleMacAddress'], json['bleMacAddress']);
      expect(restored['modelName'], json['modelName']);
      expect(restored['autoConnect'], json['autoConnect']);
      expect(restored['measurementInterval'], json['measurementInterval']);
      expect(restored['userAssignedName'], json['userAssignedName']);
    });

    test('fromJson uses model id when modelName absent', () {
      final device = BleDevice.fromJson({
        'deviceBleName': 'Luftdaten.at-X-2',
        'bleMacAddress': '112233445566',
        'deviceOriginalName': 'Luftdaten.at-X-2',
        'model': 3, // station
        'autoConnect': true,
      });
      expect(device.model, LDDeviceModel.station);
    });

    test('fourLetterCode returns last 4 chars of deviceOriginalDisplayName', () {
      final device = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-AABBCC-1',
        bleMacAddress: 'AABBCCDDEEFF',
        deviceOriginalDisplayName: 'Luftdaten.at-AABBCC-1',
      );
      expect(device.fourLetterCode, 'CC-1');
    });

    test('id returns bleMacAddress + AAA', () {
      final device = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-X-1',
        bleMacAddress: 'AABBCCDDEEFF',
        deviceOriginalDisplayName: 'Luftdaten.at-X-1',
      );
      expect(device.id, 'AABBCCDDEEFFAAA');
    });

    test('chipIdForApi uses deviceOriginalDisplayName when hex pattern', () {
      final device = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-X-1',
        bleMacAddress: 'AABBCCDDEEFF',
        deviceOriginalDisplayName: 'AABBCCDDEEFF',
      );
      expect(device.chipIdForApi, 'AABBCCDDEEFF');
    });

    test('formattedMacAddress formats with colons', () {
      final device = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-X-1',
        bleMacAddress: 'AABBCCDDEEFF',
        deviceOriginalDisplayName: 'Luftdaten.at-X-1',
      );
      expect(device.formattedMacAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('displayName returns userAssignedName when set', () {
      final device = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-X-1',
        bleMacAddress: 'AABBCCDDEEFF',
        deviceOriginalDisplayName: 'Luftdaten.at-X-1',
        userAssignedName: 'Custom Name',
      );
      expect(device.displayName, 'Custom Name');
    });

    test('displayName returns deviceOriginalDisplayName when userAssignedName null', () {
      final device = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-X-1',
        bleMacAddress: 'AABBCCDDEEFF',
        deviceOriginalDisplayName: 'Luftdaten.at-X-1',
      );
      expect(device.displayName, 'Luftdaten.at-X-1');
    });

    test('unknown factory creates unknown device', () {
      final device = BleDevice.unknown();
      expect(device.model, LDDeviceModel.unknownPortable);
      expect(device.bleName, 'unknown');
      expect(device.deviceOriginalDisplayName, 'unknown');
    });
  });

  group('LDDeviceModel', () {
    test('fromId returns correct model', () {
      expect(LDDeviceModel.fromId(1), LDDeviceModel.aRound);
      expect(LDDeviceModel.fromId(2), LDDeviceModel.cube);
      expect(LDDeviceModel.fromId(3), LDDeviceModel.station);
    });

    test('fromName returns correct model', () {
      expect(LDDeviceModel.fromName('Air aRound'), LDDeviceModel.aRound);
      expect(LDDeviceModel.fromName('Air Cube'), LDDeviceModel.cube);
    });

    test('fromLegacyId maps legacy ids', () {
      expect(LDDeviceModel.fromLegacyId(2), LDDeviceModel.aRound);
      expect(LDDeviceModel.fromLegacyId(3), LDDeviceModel.station);
      expect(LDDeviceModel.fromLegacyId(4), LDDeviceModel.badge);
      expect(LDDeviceModel.fromLegacyId(99), LDDeviceModel.unknownPortable);
    });

    test('portable is correct per model', () {
      expect(LDDeviceModel.aRound.portable, isTrue);
      expect(LDDeviceModel.cube.portable, isFalse);
      expect(LDDeviceModel.station.portable, isFalse);
    });
  });

  group('FirmwareVersion', () {
    test('toString formats version', () {
      expect(const FirmwareVersion(1, 2, 3).toString(), '1.2.3');
      expect(const FirmwareVersion(2, 0).toString(), '2.0.0');
    });
  });

  group('FormatAsMac', () {
    test('formats 12-char hex with colons', () {
      expect('AABBCCDDEEFF'.asMac, 'AA:BB:CC:DD:EE:FF');
    });
  });
}
