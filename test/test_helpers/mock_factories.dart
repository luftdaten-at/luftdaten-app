import 'package:flutter/foundation.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';

/// Creates mocks for widget and controller tests.
class MockFactories {
  MockFactories._();

  /// BatteryInfoAggregator that no-ops on add (for BatteryDetails.fromBytes tests).
  static BatteryInfoAggregator createBatteryInfoAggregator() {
    return _MockBatteryInfoAggregator();
  }
}

class _MockBatteryInfoAggregator extends BatteryInfoAggregator {
  @override
  void add(BatteryDetails details) {
    collectedBatteryDetails.add(details);
    if (details.hasReportableBattery) {
      currentBatteryDetails = details;
    }
  }

  @override
  void syncFromConnectedDevices() {}
}
