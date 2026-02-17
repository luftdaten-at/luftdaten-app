import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';

import '../../../../test_helpers/mock_factories.dart';

void main() {
  late GetIt getIt;

  setUp(() {
    getIt = GetIt.instance;
    if (getIt.isRegistered<BatteryInfoAggregator>()) {
      getIt.unregister<BatteryInfoAggregator>();
    }
    getIt.registerSingleton<BatteryInfoAggregator>(
      MockFactories.createBatteryInfoAggregator(),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<BatteryInfoAggregator>()) {
      getIt.unregister<BatteryInfoAggregator>();
    }
  });

  group('BatteryDetails.fromBytes', () {
    test('returns faulty when byte 0 is 0', () {
      final details = BatteryDetails.fromBytes([0, 50, 38]);
      expect(details.status, BatteryStatus.faulty);
      expect(details.percentage, isNull);
      expect(details.voltage, isNull);
    });

    test('returns charging when percentage >= 100 and voltage >= 4.2', () {
      final details = BatteryDetails.fromBytes([1, 100, 42]);
      expect(details.status, BatteryStatus.charging);
      expect(details.percentage, 100.0);
      expect(details.voltage, 4.2);
    });

    test('returns discharging when percentage < 100', () {
      final details = BatteryDetails.fromBytes([1, 50, 38]);
      expect(details.status, BatteryStatus.discharging);
      expect(details.percentage, 50.0);
      expect(details.voltage, 3.8);
    });

    test('returns discharging when voltage < 4.2', () {
      final details = BatteryDetails.fromBytes([1, 100, 41]);
      expect(details.status, BatteryStatus.discharging);
      expect(details.percentage, 100.0);
      expect(details.voltage, 4.1);
    });

    test('converts voltage from 0.1V units', () {
      final details = BatteryDetails.fromBytes([1, 75, 37]);
      expect(details.voltage, 3.7);
    });
  });
}
