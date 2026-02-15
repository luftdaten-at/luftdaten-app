import 'package:luftdaten.at/controller/battery_info_aggregator.dart';
import 'package:luftdaten.at/core/core.dart';

class BatteryDetails {
  final BatteryStatus status;
  final double? percentage, voltage;
  final DateTime? timestamp;

  BatteryDetails({required this.status, this.percentage, this.voltage, this.timestamp}) {
    getIt<BatteryInfoAggregator>().add(this);
  }

  /// Bytes should be bytes 0-2 from the protocol v2 specification:
  /// | 0 | Has battery status | 0: no, 1: yes |
  /// | 1 | Battery percentage (in %) |  |
  /// | 2 | Battery voltage (in 0.1V) |  |
  factory BatteryDetails.fromBytes(List<int> bytes) {
    if(bytes[0] == 0) {
      return BatteryDetails(status: BatteryStatus.faulty);
    }
    return BatteryDetails(
      status: bytes[1] >= 100 && bytes[2] >= 42 ? BatteryStatus.charging : BatteryStatus.discharging,
      percentage: bytes[1].toDouble(),
      voltage: bytes[2] / 10,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'BatteryDetails{status: $status, percentage: $percentage%, voltage: $voltage V, timestamp: $timestamp}';
  }
}

enum BatteryStatus {
  unknown, // Device is not connected / battery status has not yet been checked
  unsupported, // Device uses protocol version 1
  faulty, // Device uses protocol version 2 but no battery sensor was detected
  charging, // Device is charging (assume this is the case when percentage > 100% and voltage >= 4.2V)
  discharging, // Device is discharging, display percentage and voltage
}
