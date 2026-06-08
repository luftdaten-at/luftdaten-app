import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/domain/dimensions.dart';
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

    test('valueForDimension returns PM fields', () {
      final item = DataItem(1.0, 2.5, 10.0);
      expect(item.valueForDimension(Dimension.PM1_0), 1.0);
      expect(item.valueForDimension(Dimension.PM2_5), 2.5);
      expect(item.valueForDimension(Dimension.PM10_0), 10.0);
    });
  });

  group('SingleStationHttpProvider.parseHistoricalHourlyJson', () {
    test('parses hourly JSON rows into sorted DataItems', () {
      const body = '''
[
  {
    "time_measured": "2024-06-08T11:00:00+00:00",
    "values": [
      {"dimension": 3, "value": 3.3}
    ]
  },
  {
    "time_measured": "2024-06-08T10:00:00+00:00",
    "values": [
      {"dimension": 2, "value": 1.1},
      {"dimension": 3, "value": 2.2},
      {"dimension": 5, "value": 10.0}
    ]
  }
]
''';

      final items = SingleStationHttpProvider.parseHistoricalHourlyJson(body);

      expect(items, hasLength(2));
      expect(items[0].timestamp, DateTime.parse('2024-06-08T10:00:00+00:00'));
      expect(items[0].pm1, 1.1);
      expect(items[0].pm25, 2.2);
      expect(items[0].pm10, 10.0);
      expect(items[1].timestamp, DateTime.parse('2024-06-08T11:00:00+00:00'));
      expect(items[1].pm1, isNull);
      expect(items[1].pm25, 3.3);
      expect(items[1].pm10, isNull);
    });

    test('returns empty list for invalid payload', () {
      expect(SingleStationHttpProvider.parseHistoricalHourlyJson('{}'), isEmpty);
      expect(SingleStationHttpProvider.parseHistoricalHourlyJson('not json'), isEmpty);
    });
  });
}
