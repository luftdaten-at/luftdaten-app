import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/dashboard/data/news_item.dart';
import 'package:luftdaten.at/features/dashboard/logic/news_controller.dart';

void main() {
  late NewsController controller;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '/tmp';
      }
      if (methodCall.method == 'getTemporaryDirectory') {
        return '/tmp';
      }
      return null;
    });
  });

  setUp(() async {
    await GetStorage.init('news');
    GetStorage('news').remove('items');
    GetStorage('news').remove('lastRefresh');
    controller = NewsController();
  });

  group('NewsController', () {
    test('add inserts at front and persists', () {
      final item = NewsItem(
        timestamp: DateTime.now(),
        uid: '1',
        title: 'News 1',
        description: 'Desc 1',
      );
      controller.add(item);
      expect(controller.items.first, item);
    });

    test('remove removes item', () {
      final item = NewsItem(
        timestamp: DateTime.now(),
        uid: '1',
        title: 'News 1',
        description: 'Desc 1',
      );
      controller.add(item);
      controller.remove(item);
      expect(controller.items, isEmpty);
    });

    test('clear removes all items', () {
      controller.add(NewsItem(
        timestamp: DateTime.now(),
        uid: '1',
        title: 'T1',
        description: 'D1',
      ));
      controller.add(NewsItem(
        timestamp: DateTime.now(),
        uid: '2',
        title: 'T2',
        description: 'D2',
      ));
      controller.clear();
      expect(controller.items, isEmpty);
    });

    test('hasUnreadItems returns true when any item not dismissed', () {
      controller.add(NewsItem(
        timestamp: DateTime.now(),
        uid: '1',
        title: 'T',
        description: 'D',
        dismissed: false,
      ));
      expect(controller.hasUnreadItems(), isTrue);
    });

    test('hasUnreadItems returns false when all dismissed', () {
      controller.add(NewsItem(
        timestamp: DateTime.now(),
        uid: '1',
        title: 'T',
        description: 'D',
        dismissed: true,
      ));
      expect(controller.hasUnreadItems(), isFalse);
    });

    test('archiveItem sets dismissed to true', () {
      final item = NewsItem(
        timestamp: DateTime.now(),
        uid: '1',
        title: 'T',
        description: 'D',
        dismissed: false,
      );
      controller.add(item);
      controller.archiveItem(item);
      expect(item.dismissed, isTrue);
    });

    test('itemForId returns item matching url', () {
      final item = NewsItem(
        timestamp: DateTime.now(),
        uid: '1',
        title: 'T',
        description: 'D',
        url: 'https://luftdaten.at/post/42',
      );
      controller.add(item);
      final found = controller.itemForId('https://luftdaten.at/post/42');
      expect(found, item);
    });
  });
}
