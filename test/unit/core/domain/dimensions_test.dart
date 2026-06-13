import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/domain/dimensions.dart';

void main() {
  group('Dimension', () {
    test('getName returns name for known dimension', () {
      expect(Dimension.getName(Dimension.PM2_5), 'PM2.5');
      expect(Dimension.getName(Dimension.TEMPERATURE), 'Temperature');
    });

    test('getName returns fallback for unknown', () {
      expect(Dimension.getName(999), 'Name not found');
    });

    test('getColor returns Color for PM2_5', () {
      final c = Dimension.getColor(Dimension.PM2_5, 10);
      expect(c, isNotNull);
      expect(c.runtimeType.toString(), contains('Color'));
    });

    test('getColor returns null for unknown dimension', () {
      expect(Dimension.getColor(999, 10), isNull);
    });
  });
}
