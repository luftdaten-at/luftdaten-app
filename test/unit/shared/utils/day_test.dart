import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/shared/utils/day.dart';

void main() {
  group('Date', () {
    test('equality', () {
      const a = Date(15, 3, 2024);
      const b = Date(15, 3, 2024);
      expect(a, equals(b));
    });

    test('inequality', () {
      const a = Date(15, 3, 2024);
      const b = Date(16, 3, 2024);
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      const a = Date(15, 3, 2024);
      const b = Date(15, 3, 2024);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('GetDate on DateTime', () {
    test('extracts date from DateTime', () {
      final dt = DateTime(2024, 3, 15, 10, 30);
      final d = dt.date;
      expect(d.day, 15);
      expect(d.month, 3);
      expect(d.year, 2024);
    });
  });
}
