import 'package:flutter/foundation.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';

/// A helper to efficiently collect battery information for UI and debugging
class BatteryInfoAggregator extends ChangeNotifier {
  BatteryDetails? currentBatteryDetails;

  List<BatteryDetails> collectedBatteryDetails = [];

  bool get show => currentBatteryDetails?.hasReportableBattery ?? false;

  void onConnectionStatusUpdated() {
    syncFromConnectedDevices();
  }

  void syncFromConnectedDevices() {
    BatteryDetails? next;
    for (final device in getIt<DeviceManager>().devices) {
      if (device.state != BleDeviceState.connected) continue;
      final details = device.batteryDetails;
      if (details != null && details.hasReportableBattery) {
        next = details;
        break;
      }
    }
    if (currentBatteryDetails == next) return;
    currentBatteryDetails = next;
    notifyListeners();
  }

  void add(BatteryDetails details) {
    collectedBatteryDetails.add(details);
    syncFromConnectedDevices();
  }
}
