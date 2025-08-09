import 'package:flutter/foundation.dart';
import '../device/device_manager.dart';
import '../../../main.dart';
import '../../../data/models/device/battery_details.dart';
import '../../../data/models/ble/ble_device.dart';

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