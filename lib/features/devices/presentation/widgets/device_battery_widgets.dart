import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';

/// Battery icons for device list / detail headers.
List<Widget> deviceBatteryWidgets(BatteryDetails details) {
  Widget batteryIcon;
  Widget? batteryText;
  switch (details.status) {
    case BatteryStatus.unknown:
      return const [];
    case BatteryStatus.unsupported:
    case BatteryStatus.faulty:
      batteryIcon = const Icon(Icons.battery_unknown_outlined, color: Colors.grey, size: 20);
    case BatteryStatus.charging:
      batteryIcon = const Icon(Icons.battery_charging_full_outlined, color: Colors.green, size: 20);
    case BatteryStatus.discharging:
      final percentage = details.percentage ?? 0;
      if (percentage > 90) {
        batteryIcon = const Icon(Icons.battery_full, color: Colors.green, size: 20);
      } else if (percentage > 70) {
        batteryIcon = const Icon(Icons.battery_5_bar, color: Colors.green, size: 20);
      } else if (percentage > 40) {
        batteryIcon = const Icon(Icons.battery_4_bar, color: Colors.green, size: 20);
      } else if (percentage > 20) {
        batteryIcon = const Icon(Icons.battery_2_bar, color: Colors.orange, size: 20);
      } else {
        batteryIcon = const Icon(Icons.battery_alert, color: Colors.red, size: 20);
      }
      if (percentage <= 90) {
        batteryText = Text(
          '${details.percentage}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: percentage > 20 ? Colors.green : Colors.orange,
          ),
        );
      }
  }
  return [
    batteryIcon,
    if (batteryText != null) ...[const SizedBox(width: 2), batteryText],
    const SizedBox(width: 4),
  ];
}
