import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/core/widgets/dashboard_list_tile.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/device_manager_page.i18n.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/ble_device_notices_banner.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_battery_widgets.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_connection_appearance.dart';

class DeviceListTile extends StatelessWidget {
  const DeviceListTile({
    super.key,
    required this.device,
    required this.isStation,
    required this.onTap,
  });

  final BleDevice device;
  final bool isStation;
  final VoidCallback onTap;

  String get _subtitle => isStation
      ? device.displayName
      : device.displayName.replaceAll('Air aRound ', '');

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      notifier: device,
      builder: (context, dev) {
        final connected = dev.state == BleDeviceState.connected;
        final statusColor = DeviceConnectionAppearance.statusColor(context, dev.state);
        final scheme = Theme.of(context).colorScheme;
        final background = connected
            ? Color.alphaBlend(statusColor.withValues(alpha: 0.12), scheme.primaryContainer)
            : scheme.primaryContainer;

        return DashboardListTile(
          title: dev.model.name,
          subtitle: _subtitle,
          backgroundColor: background,
          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BleDeviceNoticesBanner(device: dev, compact: true),
              Icon(
                DeviceConnectionAppearance.bluetoothIcon(dev.state),
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 2),
              Text(
                DeviceConnectionAppearance.statusLabelKey(dev.state).i18n,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
              ),
              if (connected && dev.batteryDetails?.hasReportableBattery == true)
                ...deviceBatteryWidgets(dev.batteryDetails!),
            ],
          ),
        );
      },
    );
  }
}
