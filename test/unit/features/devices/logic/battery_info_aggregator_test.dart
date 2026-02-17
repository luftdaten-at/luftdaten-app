import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';

void main() {
  late BatteryInfoAggregator aggregator;
  late DeviceManager deviceManager;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') return '/tmp';
      if (methodCall.method == 'getTemporaryDirectory') return '/tmp';
      return null;
    });
  });

  setUp(() async {
    await GetStorage.init('devices');
    GetStorage('devices').remove('devices');
    GetIt.instance.reset();
    deviceManager = DeviceManager();
    GetIt.instance.registerSingleton<DeviceManager>(deviceManager);
    aggregator = BatteryInfoAggregator();
    GetIt.instance.registerSingleton<BatteryInfoAggregator>(aggregator);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('BatteryInfoAggregator', () {
    test('add updates currentBatteryDetails and collects', () {
      final details = BatteryDetails.fromBytes([1, 75, 37]);
      aggregator.add(details);

      expect(aggregator.currentBatteryDetails, details);
      expect(aggregator.collectedBatteryDetails, contains(details));
    });

    test('add with multiple details keeps latest as current', () {
      final d1 = BatteryDetails.fromBytes([1, 50, 38]);
      final d2 = BatteryDetails.fromBytes([1, 90, 41]);
      aggregator.add(d1);
      aggregator.add(d2);

      expect(aggregator.currentBatteryDetails, d2);
      expect(aggregator.collectedBatteryDetails, contains(d1));
      expect(aggregator.collectedBatteryDetails, contains(d2));
    });

    test('show is false when no device connected', () {
      aggregator.add(BatteryDetails.fromBytes([1, 75, 37]));
      aggregator.onConnectionStatusUpdated();
      expect(aggregator.show, isFalse);
    });
  });
}
