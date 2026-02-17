import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/dashboard/logic/favorites_manager.dart';

void main() {
  late FavoritesManager manager;

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
    await GetStorage.init('favorites');
    GetStorage('favorites').remove('fav');
    manager = FavoritesManager();
    if (GetIt.instance.isRegistered<FavoritesManager>()) {
      GetIt.instance.unregister<FavoritesManager>();
    }
    GetIt.instance.registerSingleton<FavoritesManager>(manager);
  });

  tearDown(() async {
    if (GetIt.instance.isRegistered<FavoritesManager>()) {
      GetIt.instance.unregister<FavoritesManager>();
    }
  });

  group('FavoritesManager', () {
    test('init loads empty list when storage is empty', () async {
      await manager.init();
      expect(manager.favorites, isEmpty);
    });

    test('add adds favorite and notifies', () async {
      await manager.init();
      final fav = Favorite(id: '123', latLng: LatLng(48.0, 16.0));
      manager.add(fav);
      expect(manager.favorites, [fav]);
    });

    test('hasId returns true when favorite exists', () async {
      await manager.init();
      manager.add(Favorite(id: 'abc', latLng: LatLng(48.0, 16.0)));
      expect(manager.hasId('abc'), isTrue);
      expect(manager.hasId('xyz'), isFalse);
    });

    test('removeId removes favorite by id', () async {
      await manager.init();
      manager.add(Favorite(id: '1', latLng: LatLng(48.0, 16.0)));
      manager.add(Favorite(id: '2', latLng: LatLng(49.0, 17.0)));
      manager.removeId('1');
      expect(manager.favorites.length, 1);
      expect(manager.favorites.first.id, '2');
    });

    test('addByIdAndLocation creates and adds favorite', () async {
      await manager.init();
      manager.addByIdAndLocation('station-1', LatLng(48.2, 16.3));
      expect(manager.favorites.length, 1);
      expect(manager.favorites.first.id, 'station-1');
      expect(manager.favorites.first.latLng.latitude, 48.2);
      expect(manager.favorites.first.latLng.longitude, 16.3);
    });

    test('remove removes favorite by reference', () async {
      await manager.init();
      final fav = Favorite(id: 'x', latLng: LatLng(48.0, 16.0));
      manager.add(fav);
      manager.remove(fav);
      expect(manager.favorites, isEmpty);
    });

    test('reset clears all favorites', () async {
      await manager.init();
      manager.add(Favorite(id: '1', latLng: LatLng(48.0, 16.0)));
      manager.add(Favorite(id: '2', latLng: LatLng(49.0, 17.0)));
      manager.reset();
      expect(manager.favorites, isEmpty);
    });

    test('persists across init', () async {
      manager.add(Favorite(id: 'persist', latLng: LatLng(48.0, 16.0)));
      final manager2 = FavoritesManager();
      await manager2.init();
      expect(manager2.favorites.any((f) => f.id == 'persist'), isTrue);
    });
  });

  group('Favorite', () {
    test('fromJson and toJson roundtrip', () {
      final latLng = LatLng(48.1, 16.1);
      final original = Favorite(
        id: 'fav-1',
        latLng: latLng,
        locationString: 'Vienna',
        name: 'My Station',
      );
      final json = original.toJson();
      final restored = Favorite.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.latLng.latitude, original.latLng.latitude);
      expect(restored.latLng.longitude, original.latLng.longitude);
      expect(restored.locationString, original.locationString);
      expect(restored.name, original.name);
    });
  });
}
