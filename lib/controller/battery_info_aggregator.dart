import 'package:flutter/foundation.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/model/battery_details.dart';
import 'package:luftdaten.at/model/ble_device.dart';

/// A helper to efficiently collect battery information for UI and debugging
class BatteryInfoAggregator extends ChangeNotifier {
  BatteryDetails? currentBatteryDetails;

  List<BatteryDetails> collectedBatteryDetails = [];

  bool _show = false;

  bool get show {
    return _show && currentBatteryDetails != null;
  }

  void onConnectionStatusUpdated() {
    bool newShow = getIt<DeviceManager>().devices.any((e) => e.state == BleDeviceState.connected);
    if (_show != newShow) {
      _show = newShow;
      notifyListeners();
    }
  }

  void add(BatteryDetails details) {
    currentBatteryDetails = details;
    collectedBatteryDetails.add(details);
    notifyListeners();
  }
}