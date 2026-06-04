import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';

import 'ble_device_notices_banner.i18n.dart';
import 'ble_device_notices_presenter.dart';

/// Shows operational notices from BLE `device_status` (firmware flags + Wi‑Fi detail).
class BleDeviceNoticesBanner extends StatelessWidget {
  const BleDeviceNoticesBanner({
    super.key,
    required this.device,
    this.compact = false,
  });

  final BleDevice device;
  final bool compact;

  static String messageForNotice(BleDeviceNotice notice) {
    return switch (notice.id) {
      'config_incomplete' => 'Konfiguration unvollständig',
      'no_sensor' => 'Kein Sensor verbunden',
      'wifi_failure' => 'WLAN-Verbindung fehlgeschlagen',
      'wifi_credentials_missing' => 'WLAN: Zugangsdaten nicht konfiguriert',
      'wifi_ssid_not_found' => 'WLAN: SSID nicht gefunden',
      'wifi_connection_failed' => 'WLAN: Verbindung fehlgeschlagen (Passwort, Timeout, …)',
      _ => notice.id,
    }.i18n;
  }

  @override
  Widget build(BuildContext context) {
    if (device.state != BleDeviceState.connected) {
      return const SizedBox.shrink();
    }
    final notices = device.operationalNotices;
    if (notices.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return IconButton(
        icon: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
        tooltip: 'Gerätestatus'.i18n,
        onPressed: () => BleDeviceNoticesPresenter.showNoticesDialog(context, notices),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: notices.map((n) => _NoticeRow(notice: n)).toList(),
      ),
    );
  }

}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice});

  final BleDeviceNotice notice;

  @override
  Widget build(BuildContext context) {
    final isError = notice.severity == BleNoticeSeverity.error;
    final color = isError ? Colors.red.shade700 : Colors.orange.shade800;
    final bg = isError ? Colors.red.shade50 : Colors.orange.shade50;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.warning_amber_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  BleDeviceNoticesBanner.messageForNotice(notice),
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
