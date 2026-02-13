import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/shared/utils/map_extensions.dart';

void main() {
  group('MapToJson', () {
    test('casts map to Map<String, dynamic>', () {
      final input = {'a': 1, 'b': 'x'};
      final result = input.json;
      expect(result, isA<Map<String, dynamic>>());
      expect(result['a'], 1);
      expect(result['b'], 'x');
    });
  });
}
