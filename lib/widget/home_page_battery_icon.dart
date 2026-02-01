import 'package:flutter/material.dart';
import 'package:luftdaten.at/page/home_page.i18n.dart';

import '../controller/battery_info_aggregator.dart';
import 'package:luftdaten.at/core/core.dart';
import '../model/battery_details.dart';
import 'package:luftdaten.at/shared/widgets/change_notifier_builder.dart';

class HomePageBatteryIcon extends StatelessWidget {
  const HomePageBatteryIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      notifier: getIt<BatteryInfoAggregator>(),
      builder: (context, batteryInfoAggregator) {
        if (!batteryInfoAggregator.show) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Tooltip(
            message: 'Batteriestatus'.i18n,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildIcon(batteryInfoAggregator),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(BatteryInfoAggregator batteryInfoAggregator) {
    switch (batteryInfoAggregator.currentBatteryDetails!.status) {
      case BatteryStatus.unknown:
        return const SizedBox();
      case BatteryStatus.unsupported:
      case BatteryStatus.faulty:
        return const Icon(Icons.battery_unknown_outlined, color: Colors.grey);
      case BatteryStatus.charging:
        return const Icon(Icons.battery_charging_full_outlined, color: Colors.green);
      case BatteryStatus.discharging:
      // Depends on battery percentage
        double percentage = batteryInfoAggregator.currentBatteryDetails!.percentage ?? 0;
        if (percentage > 90) {
          return Icon(Icons.battery_full, color: Colors.greenAccent.shade200);
        } else if (percentage > 70) {
          return Icon(Icons.battery_5_bar, color: Colors.greenAccent.shade200);
        } else if (percentage > 40) {
          return Icon(Icons.battery_4_bar, color: Colors.greenAccent.shade200);
        } else if (percentage > 20) {
          return Icon(Icons.battery_2_bar, color: Colors.orangeAccent.shade200);
        } else {
          return Icon(Icons.battery_alert, color: Colors.redAccent.shade200);
        }
    }
  }
}
