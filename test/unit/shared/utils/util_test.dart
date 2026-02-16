import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/utils/util.dart';

void main() {
  group('Util.toByteArray', () {
    test('converts int to 4-byte big-endian', () {
      final result = Util.toByteArray(0x12345678);
      expect(result.length, 4);
      expect(result[0], 0x12);
      expect(result[1], 0x34);
      expect(result[2], 0x56);
      expect(result[3], 0x78);
    });

    test('converts double to 8-byte big-endian', () {
      final result = Util.toByteArray(1.0);
      expect(result.length, 8);
    });

    test('converts string to UTF-8 code units', () {
      final result = Util.toByteArray('AB');
      expect(result, [65, 66]);
    });

    test('throws for invalid type', () {
      expect(() => Util.toByteArray(true), throwsArgumentError);
    });
  });
}
