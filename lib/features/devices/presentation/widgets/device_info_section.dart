import 'package:clipboard/clipboard.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/core/widgets/dashboard_list_tile.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_sync.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/ble_device_notices_banner.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_connection_appearance.dart';

import '../pages/device_detail_page.i18n.dart';

/// Inline device metadata, firmware, and configuration for the device detail page.
class DeviceInfoSection extends StatelessWidget {
  const DeviceInfoSection({
    super.key,
    required this.device,
    required this.isStation,
    required this.isLoading,
    this.configSyncResult,
    this.configLoading = false,
    this.wifiSsid,
    this.wifiPasswordStored = false,
  });

  final BleDevice device;
  final bool isStation;
  final bool isLoading;
  final DeviceConfigSyncResult? configSyncResult;
  final bool configLoading;
  final String? wifiSsid;
  final bool wifiPasswordStored;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeading(title: 'Geräteinfo'.i18n, bottomSpacing: 8),
          if (isLoading)
            _loadingRow()
          else if (device.state == BleDeviceState.connected)
            isStation ? _buildStationInfo(context) : _buildPortableInfo(context)
          else
            Text(
              'Geräteinfo ist nach der Verbindung verfügbar'.i18n,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          if (!isLoading) ...[
            const SizedBox(height: 12),
            _buildConfigurationSection(context),
          ],
        ],
      ),
    );
  }

  Widget _loadingRow() {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Geräteinfo wird geladen…'.i18n,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _metadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BleDeviceState state) {
    return DeviceConnectionAppearance.statusLabelKey(state).i18n;
  }

  Widget _buildPortableInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (device.firmwareVersion != null)
          _metadataRow('Firmware-Version: '.i18n, device.firmwareVersion.toString()),
        _metadataRow('Name: '.i18n, device.displayName),
        _metadataRow('Adresse: '.i18n, device.bleMacAddress.asMac),
        _metadataRow('Status: '.i18n, _statusLabel(device.state)),
      ],
    );
  }

  Widget _buildStationInfo(BuildContext context) {
    final macBytes = hex.decode(device.bleMacAddress);
    macBytes[macBytes.length - 1] = macBytes[macBytes.length - 1] - 1;
    final chipId = hex.encode(macBytes.reversed.toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (device.firmwareVersion != null)
          _metadataRow('Firmware-Version: '.i18n, device.firmwareVersion.toString()),
        _metadataRow('Gerät: '.i18n, device.deviceOriginalDisplayName),
        _metadataRow('Adresse: '.i18n, device.bleMacAddress.asMac),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text('Sensor-ID: '.i18n),
              Text(chipId, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  FlutterClipboard.copy(chipId);
                  Fluttertoast.showToast(msg: 'Sensor-ID kopiert!'.i18n);
                },
                child: const Icon(Icons.copy, size: 14, color: Colors.grey),
              ),
              InkWell(
                onTap: () {
                  showLDDialog(
                    context,
                    title: 'Sensor-ID'.i18n,
                    icon: Icons.help_outline_outlined,
                    text: 'Die Sensor-ID wird benötigt, um die Station in der '
                            'Sensor.Community einzutragen. Anweisungen hierzu findest '
                            'du auf unserer Webseite.'
                        .i18n,
                  );
                },
                child: const Icon(Icons.help_outline, size: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Konfiguration'.i18n,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (configLoading)
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Konfiguration wird geladen…'.i18n,
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ),
            ],
          )
        else if (isStation)
          _buildStationConfigContent(context)
        else
          _buildPortableConfigContent(context),
      ],
    );
  }

  Widget _buildStationConfigContent(BuildContext context) {
    final record = configSyncResult?.localRecord;
    final children = <Widget>[];

    if (record == null) {
      children.add(
        Text(
          'Keine gespeicherte Konfiguration'.i18n,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      );
    } else {
      final cfg = record.config;
      final lastAt = record.lastConfiguredAt ?? cfg.lastConfiguredAt;

      if (device.state == BleDeviceState.connected) {
        children.add(_syncBadge(context));
      }
      if (lastAt != null) {
        children.add(
          _metadataRow(
            'Zuletzt konfiguriert: '.i18n,
            DateFormat('dd.MM.yyyy HH:mm').format(lastAt),
          ),
        );
      }
      if (cfg.deviceId != null && cfg.deviceId!.isNotEmpty) {
        children.add(_metadataRow('Device-ID: '.i18n, cfg.deviceId!));
      }
      children.addAll([
        _metadataRow('Messintervall: '.i18n, cfg.measurementInterval.toString()),
        _metadataRow('Auto-Update: '.i18n, cfg.autoUpdateMode.toString()),
      ]);
      if (cfg.latitude != null && cfg.longitude != null) {
        children.add(
          _metadataRow(
            'Standort: '.i18n,
            '${cfg.latitude!.toStringAsFixed(5)}, ${cfg.longitude!.toStringAsFixed(5)}'
            '${cfg.height != null ? ' (${cfg.height!.toStringAsFixed(0)} m)' : ''}',
          ),
        );
      }
      if (cfg.tz != null && cfg.tz!.isNotEmpty) {
        children.add(_metadataRow('Zeitzone: '.i18n, cfg.tz!));
      }
      children.add(
        _metadataRow(
          'MQTT: '.i18n,
          cfg.mqttEnabled
              ? (cfg.mqttBroker?.isNotEmpty == true ? cfg.mqttBroker! : 'Aktiv'.i18n)
              : 'Aus'.i18n,
        ),
      );
    }

    if (children.isNotEmpty) {
      children.add(const SizedBox(height: 8));
    }
    children.addAll(_buildWifiConfigurationRows(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  List<Widget> _buildWifiConfigurationRows(BuildContext context) {
    final rows = <Widget>[];
    final hasStoredSsid = wifiSsid != null && wifiSsid!.isNotEmpty;
    final hasStoredWifi = hasStoredSsid || wifiPasswordStored;

    if (!hasStoredWifi) {
      rows.add(_metadataRow('WLAN: '.i18n, 'Nicht konfiguriert'.i18n));
    } else {
      if (hasStoredSsid) {
        rows.add(_metadataRow('WLAN SSID: '.i18n, wifiSsid!));
      }
      rows.add(
        _metadataRow(
          'WLAN Passwort: '.i18n,
          wifiPasswordStored ? 'Gespeichert'.i18n : 'Nicht gespeichert'.i18n,
        ),
      );
    }

    if (device.state == BleDeviceState.connected) {
      BleDeviceNotice? wifiNotice;
      for (final notice in device.operationalNotices) {
        if (notice.id.startsWith('wifi_')) {
          wifiNotice = notice;
          break;
        }
      }
      if (wifiNotice != null) {
        rows.add(
          _metadataRow(
            'WLAN auf Gerät: '.i18n,
            BleDeviceNoticesBanner.messageForNotice(wifiNotice),
          ),
        );
      } else if (device.wifiSsidConfiguredOnDevice) {
        rows.add(
          _metadataRow(
            'WLAN auf Gerät: '.i18n,
            'SSID konfiguriert'.i18n,
          ),
        );
      } else {
        rows.add(
          _metadataRow(
            'WLAN auf Gerät: '.i18n,
            'SSID nicht konfiguriert'.i18n,
          ),
        );
      }
    } else {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'WLAN-Gerätestatus nach Verbindung verfügbar'.i18n,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return rows;
  }

  Widget _buildPortableConfigContent(BuildContext context) {
    final portable = configSyncResult?.portableRecord;
    if (portable == null) {
      return Text(
        'Keine gespeicherte Konfiguration'.i18n,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (device.state == BleDeviceState.connected) _syncBadge(context),
        if (portable.lastConfiguredAt != null)
          _metadataRow(
            'Zuletzt konfiguriert: '.i18n,
            DateFormat('dd.MM.yyyy HH:mm').format(portable.lastConfiguredAt!),
          ),
        _metadataRow(
          'Anzeigename: '.i18n,
          portable.userAssignedName ?? device.displayName,
        ),
        _metadataRow(
          'Messintervall (App): '.i18n,
          '${portable.measurementInterval} s',
        ),
        _metadataRow(
          'Automatisch verbinden: '.i18n,
          portable.autoReconnect ? 'Ja'.i18n : 'Nein'.i18n,
        ),
      ],
    );
  }

  Widget _syncBadge(BuildContext context) {
    final status = configSyncResult?.status;
    if (status == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    late final String label;
    late final Color color;

    if (isStation) {
      switch (status) {
        case DeviceConfigSyncStatus.inSync:
          label = 'Konfiguration aktuell'.i18n;
          color = scheme.primary;
        case DeviceConfigSyncStatus.outOfSync:
          label = 'Konfiguration abweichend'.i18n;
          color = scheme.tertiary;
        case DeviceConfigSyncStatus.noLocalConfig:
          label = 'Keine lokale Konfiguration'.i18n;
          color = scheme.outline;
        case DeviceConfigSyncStatus.bleReadFailed:
          label = 'BLE-Konfiguration nicht lesbar'.i18n;
          color = scheme.error;
        case DeviceConfigSyncStatus.localOnly:
          label = 'Nur App-Einstellung'.i18n;
          color = scheme.outline;
      }
    } else {
      label = 'Nur App-Einstellung'.i18n;
      color = scheme.outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(
                status == DeviceConfigSyncStatus.inSync
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
