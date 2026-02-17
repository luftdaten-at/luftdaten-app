import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/map/logic/http_provider.dart';

void main() {
  group('DataItem', () {
    test('toString formats values', () {
      final item = DataItem(1.0, 2.5, 10.0);
      expect(item.toString(), contains('1.0'));
      expect(item.toString(), contains('2.5'));
      expect(item.toString(), contains('10.0'));
    });

    test('holds optional timestamp', () {
      final ts = DateTime.utc(2024, 1, 15);
      final item = DataItem(1.0, 2.5, 10.0, ts);
      expect(item.timestamp, ts);
    });
  });
}
