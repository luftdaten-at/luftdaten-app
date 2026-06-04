import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';

import 'ble_device_notices_banner.dart';
import 'ble_device_notices_banner.i18n.dart';

/// Shows operational notices from BLE `device_status` (e.g. after connect).
class BleDeviceNoticesPresenter {
  BleDeviceNoticesPresenter._();

  /// Dialog body: optional device name + notice messages.
  static Widget buildNoticesDialogContent(
    List<BleDeviceNotice> notices, {
    String? deviceDisplayName,
  }) {
    final children = <Widget>[];
    if (deviceDisplayName != null && deviceDisplayName.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Gerät: %s'.i18n.fill([deviceDisplayName]),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    children.addAll(
      notices.map(
        (n) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(BleDeviceNoticesBanner.messageForNotice(n)),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  static Future<void> showNoticesDialog(
    BuildContext context,
    List<BleDeviceNotice> notices, {
    String? deviceDisplayName,
  }) {
    if (notices.isEmpty) return Future.value();
    return showLDDialog(
      context,
      title: 'Gerätestatus'.i18n,
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
      content: buildNoticesDialogContent(notices, deviceDisplayName: deviceDisplayName),
    );
  }

  /// Called once after a successful [BleDevice.connect] when notices are present.
  static void showAfterConnectIfNeeded(BleDevice device) {
    final notices = device.operationalNotices;
    if (notices.isEmpty) return;
    final context = globalKey.currentContext;
    if (context == null) return;
    try {
      showNoticesDialog(context, notices, deviceDisplayName: device.displayName);
    } catch (_) {}
  }
}
