import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/model/chip_id.dart';

void main() {
  group('ChipId', () {
    test('unknown() has chipId 000000000000', () {
      const id = ChipId.unknown();
      expect(id.chipId, '000000000000');
    });

    test('fromMac converts mac to chipId via extension', () {
      const mac = '112233445566';
      const id = ChipId.fromMac(mac);
      expect(id.chipId, isNot(mac));
      expect(id.mac, mac);
    });

    test('fromChipId stores chipId', () {
      const chipId = 'AABBCCDDEEFF';
      const id = ChipId.fromChipId(chipId);
      expect(id.chipId, chipId);
      expect(id.mac, isNot(chipId));
    });

    test('toJson and fromJson roundtrip', () {
      const id = ChipId.fromChipId('AABBCCDDEEFF');
      final json = id.toJson();
      final restored = ChipId.fromJson(json);
      expect(restored.chipId, id.chipId);
      expect(restored.mac, id.mac);
    });
  });

  group('MacToChipId extension', () {
    test('chipId and mac roundtrip', () {
      const mac = '112233445566';
      final chipId = mac.chipId;
      expect(chipId.mac, mac);
    });

    test('chipId from mac is different from mac', () {
      const mac = 'AABBCCDDEEFF';
      final chipId = mac.chipId;
      expect(chipId, isNot(mac));
    });
  });
}
