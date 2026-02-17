import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/utils/list_extensions.dart';

void main() {
  group('IterableMean', () {
    test('mean of single value returns that value', () {
      expect([5.0].mean, 5.0);
    });

    test('mean of multiple values', () {
      expect([2.0, 4.0, 6.0].mean, 4.0);
    });

    test('mean of empty list returns NaN', () {
      expect(<num>[].mean.isNaN, isTrue);
    });
  });

  group('ListRemoveNulls', () {
    test('removes nulls from list', () {
      final list = <int?>[1, null, 2, null, 3];
      expect(list.removeListNulls(), [1, 2, 3]);
    });

    test('returns empty when all null', () {
      expect(<int?>[null, null].removeListNulls(), isEmpty);
    });
  });

  group('SpaceWith', () {
    test('empty list returns as-is', () {
      expect(<int>[].spaceWith(0), isEmpty);
    });

    test('single element returns as-is', () {
      expect([1].spaceWith(0), [1]);
    });

    test('inserts spacer between elements', () {
      expect([1, 2, 3].spaceWith(0), [1, 0, 2, 0, 3]);
    });

    test('spaceWith first adds first spacer', () {
      expect([1, 2].spaceWith(0, first: -1), [1, -1, 2]);
    });
  });

  group('SpaceWithList', () {
    test('inserts list spacer between elements', () {
      expect([1, 2].spaceWithList([10, 20]), [1, 10, 20, 2]);
    });
  });

  group('AllIndiciesOf', () {
    test('finds all matching indices', () {
      expect([1, 2, 1, 3, 1].allIndicesOf((e) => e == 1), [0, 2, 4]);
    });

    test('returns empty when no match', () {
      expect([1, 2, 3].allIndicesOf((e) => e > 10), isEmpty);
    });
  });
}
