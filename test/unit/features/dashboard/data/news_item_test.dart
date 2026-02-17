import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/dashboard/data/news_item.dart';

void main() {
  group('NewsItem', () {
    test('fromJson parses all fields', () {
      final json = {
        'timestamp': '2024-01-15T10:00:00.000Z',
        'uid': '12345',
        'title': 'Test Title',
        'description': 'Test Description',
        'url': 'https://example.com',
        'dismissed': true,
      };
      final item = NewsItem.fromJson(json);
      expect(item.timestamp, DateTime.utc(2024, 1, 15, 10));
      expect(item.uid, '12345');
      expect(item.title, 'Test Title');
      expect(item.description, 'Test Description');
      expect(item.url, 'https://example.com');
      expect(item.dismissed, isTrue);
    });

    test('fromJson defaults dismissed to false when absent', () {
      final json = {
        'timestamp': '2024-01-15T10:00:00.000Z',
        'uid': '1',
        'title': 'T',
        'description': 'D',
      };
      final item = NewsItem.fromJson(json);
      expect(item.dismissed, isFalse);
    });

    test('toJson roundtrips with fromJson', () {
      final original = NewsItem(
        timestamp: DateTime.utc(2024, 3, 1, 12, 30),
        uid: 'uid-1',
        title: 'Title',
        description: 'Description',
        url: 'https://luftdaten.at/news/1',
        dismissed: true,
      );
      final json = original.toJson();
      final restored = NewsItem.fromJson(json);
      expect(restored.timestamp, original.timestamp);
      expect(restored.uid, original.uid);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.url, original.url);
      expect(restored.dismissed, original.dismissed);
    });

    test('toJson omits url when null', () {
      final item = NewsItem(
        timestamp: DateTime.now(),
        uid: '1',
        title: 'T',
        description: 'D',
        url: null,
      );
      final json = item.toJson();
      expect(json.containsKey('url'), isFalse);
    });
  });
}
