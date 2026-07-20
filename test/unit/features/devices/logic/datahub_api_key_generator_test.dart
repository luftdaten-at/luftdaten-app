import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/logic/datahub_api_key_generator.dart';

void main() {
  group('DatahubApiKeyGenerator.generate', () {
    test('returns 32 characters by default', () {
      expect(DatahubApiKeyGenerator.generate().length, 32);
    });

    test('uses only lowercase letters and digits', () {
      final key = DatahubApiKeyGenerator.generate(
        random: Random(42),
      );
      expect(key, matches(RegExp(r'^[a-z0-9]+$')));
    });

    test('respects custom length when at least minLength', () {
      expect(
        DatahubApiKeyGenerator.generate(length: 20, random: Random(1)).length,
        20,
      );
    });

    test('throws when length is below minLength', () {
      expect(
        () => DatahubApiKeyGenerator.generate(length: 8),
        throwsArgumentError,
      );
    });
  });
}
