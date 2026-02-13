import 'package:flutter/foundation.dart';
import 'package:luftdaten.at/controller/battery_info_aggregator.dart';
import 'package:luftdaten.at/model/battery_details.dart';

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
    // No-op; avoid DeviceManager dependency
    currentBatteryDetails = details;
    collectedBatteryDetails.add(details);
    // Don't call notifyListeners to avoid trigger chain
  }
}
