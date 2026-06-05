import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_store.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_sync.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/air_station_config_wizard_page.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/air_station_sd_ble_import.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/air_station_startup_flags_dialog.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/ble_device_notices_banner.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_connect_button.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_connection_appearance.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_info_section.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_sensors_section.dart';

import 'device_manager_page.dart';
import 'device_detail_page.i18n.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({
    super.key,
    required this.device,
    required this.isStation,
  });

  final BleDevice device;
  final bool isStation;

  static const String route = 'device-detail';

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  Timer? _statusPollTimer;
  bool _sdBleExportNonEmpty = false;
  DateTime? _lastSdBleExportPeekAt;
  bool _bleBootstrapInProgress = false;
  bool _bootstrapAttempted = false;
  bool _awaitingConnectForBootstrap = false;
  bool _connectBootstrapCompleted = false;
  DeviceConfigSyncResult? _configSyncResult;
  bool _configSnapshotLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapBle());
      unawaited(_refreshConfigSnapshot(widget.device));
    });
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapBle() async {
    final device = widget.device;
    if (!mounted) return;
    setState(() {
      _bleBootstrapInProgress = true;
      _bootstrapAttempted = true;
    });

    try {
      if (device.state == BleDeviceState.connected) {
        await getIt<BleController>().refreshDeviceInfo(device);
        if (!mounted) return;
        _onBootstrapConnected();
      } else if (device.state == BleDeviceState.connecting) {
        _awaitingConnectForBootstrap = true;
      } else {
        final ok = await device.connect(showNoticesOnConnect: false);
        if (!mounted) return;
        if (ok && device.state == BleDeviceState.connected) {
          await getIt<BleController>().refreshDeviceStatus(device);
          _onBootstrapConnected();
        }
      }
    } finally {
      if (mounted) setState(() => _bleBootstrapInProgress = false);
    }
  }

  void _onBootstrapConnected() {
    _startStatusPoll();
    if (widget.isStation) {
      unawaited(_peekSdBleExportAvailability());
    }
    unawaited(_refreshConfigSnapshot(widget.device));
  }

  Future<void> _refreshConfigSnapshot(BleDevice device) async {
    if (!mounted) return;
    setState(() => _configSnapshotLoading = true);
    try {
      if (widget.isStation) {
        if (device.state == BleDeviceState.connected) {
          final result = await DeviceConfigSyncChecker.checkStation(device);
          if (!mounted) return;
          setState(() => _configSyncResult = result);
        } else {
          final local =
              await DeviceConfigStore.instance.readStationConfig(device.bleName);
          if (!mounted) return;
          setState(() => _configSyncResult = DeviceConfigSyncResult(
                status: local == null
                    ? DeviceConfigSyncStatus.noLocalConfig
                    : DeviceConfigSyncStatus.noLocalConfig,
                localRecord: local,
              ));
        }
      } else {
        final portable =
            await DeviceConfigStore.instance.readPortableConfig(device.bleName);
        if (!mounted) return;
        setState(() => _configSyncResult = DeviceConfigSyncChecker.portableResult(portable));
      }
    } finally {
      if (mounted) setState(() => _configSnapshotLoading = false);
    }
  }

  Future<void> _completeBootstrapAfterConnect() async {
    if (_connectBootstrapCompleted) return;
    _connectBootstrapCompleted = true;
    _awaitingConnectForBootstrap = false;
    await getIt<BleController>().refreshDeviceInfo(widget.device);
    if (!mounted) return;
    _onBootstrapConnected();
    setState(() {});
  }

  void _startStatusPoll() {
    _statusPollTimer?.cancel();
    if (widget.device.state != BleDeviceState.connected) return;
    unawaited(getIt<BleController>().refreshDeviceStatus(widget.device));
    _statusPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (widget.device.state == BleDeviceState.connected) {
        unawaited(getIt<BleController>().refreshDeviceStatus(widget.device));
      }
    });
  }

  Future<void> _peekSdBleExportAvailability() async {
    final device = widget.device;
    if (device.state != BleDeviceState.connected) return;
    final now = DateTime.now();
    if (_lastSdBleExportPeekAt != null &&
        now.difference(_lastSdBleExportPeekAt!) < const Duration(seconds: 10)) {
      return;
    }
    _lastSdBleExportPeekAt = now;
    try {
      final info = await getIt<BleController>().peekSdBleExport(device);
      if (!mounted) return;
      setState(() => _sdBleExportNonEmpty = info?.sdLogNonEmpty ?? false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sdBleExportNonEmpty = false);
    }
  }

  String _statusLabel(BleDeviceState state) {
    return DeviceConnectionAppearance.statusLabelKey(state).i18n;
  }

  bool _isBleLoading(BleDevice device) {
    return _bleBootstrapInProgress ||
        device.state == BleDeviceState.connecting ||
        _awaitingConnectForBootstrap;
  }

  Widget _buildBootstrapBanner(BleDevice device) {
    if (!_isBleLoading(device)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verbinde mit Gerät…'.i18n,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionFailureBanner(BleDevice device) {
    if (!_bootstrapAttempted || _isBleLoading(device)) return const SizedBox.shrink();
    if (device.state == BleDeviceState.connected) return const SizedBox.shrink();

    final color = DeviceConnectionAppearance.statusColor(context, device.state);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.bluetooth_disabled, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusLabel(device.state),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      notifier: widget.device,
      builder: (context, device) {
        if (_awaitingConnectForBootstrap && device.state == BleDeviceState.connected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_completeBootstrapAfterConnect());
          });
        }
        if (device.state == BleDeviceState.connected && _statusPollTimer == null && !_awaitingConnectForBootstrap) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startStatusPoll());
        }
        if (device.state != BleDeviceState.connected && _statusPollTimer != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _statusPollTimer?.cancel();
            _statusPollTimer = null;
          });
        }
        if (widget.isStation &&
            device.state == BleDeviceState.connected &&
            _lastSdBleExportPeekAt == null &&
            !_awaitingConnectForBootstrap) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_peekSdBleExportAvailability());
          });
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            title: Text(
              device.displayName,
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),
            actions: [
              if (widget.isStation)
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AirStationRenamingDialog(device: device),
                    );
                  },
                  icon: const Icon(Icons.draw, color: Colors.white),
                  tooltip: 'Umbenennen'.i18n,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      DeviceConnectionAppearance.bluetoothIcon(device.state),
                      color: DeviceConnectionAppearance.statusColor(context, device.state),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusLabel(device.state),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DeviceConnectButton(device: device),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBootstrapBanner(device),
                _buildConnectionFailureBanner(device),
                BleDeviceNoticesBanner(device: device),
                DeviceSensorsSection(
                  device: device,
                  isLoading: _isBleLoading(device),
                ),
                DeviceInfoSection(
                  device: device,
                  isStation: widget.isStation,
                  isLoading: _isBleLoading(device),
                  configSyncResult: _configSyncResult,
                  configLoading: _configSnapshotLoading,
                ),
                if (widget.isStation)
                  _buildStationActions(context, device)
                else
                  _buildPortableActions(context, device),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _deviceActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool enabled = true,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.primary;
    return FilledButton.tonalIcon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: FilledButton.styleFrom(
        backgroundColor: enabled ? bg.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
        foregroundColor: enabled ? bg : scheme.onSurface.withValues(alpha: 0.38),
      ),
    );
  }

  Widget _buildPortableActions(BuildContext context, BleDevice device) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _deviceActionButton(
          context,
          icon: Icons.settings,
          label: 'Gerät konfigurieren'.i18n,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => DeviceConfigDialog(device: device),
            );
          },
        ),
        _deviceActionButton(
          context,
          icon: Icons.delete,
          label: 'Gerät entfernen'.i18n,
          color: Theme.of(context).colorScheme.error,
          onPressed: () => _confirmDeleteDevice(context, device),
        ),
      ],
    );
  }

  Widget _buildStationActions(BuildContext context, BleDevice device) {
    return ListenableBuilder(
      listenable: AppSettings.I,
      builder: (context, _) {
        final actions = <Widget>[
          _deviceActionButton(
            context,
            icon: Icons.settings,
            label: 'Gerät konfigurieren'.i18n,
            onPressed: () {
              final controller = AirStationConfigWizardController(device.bleName);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AirStationConfigWizardPage(controller: controller),
                ),
              );
            },
          ),
          if (AppSettings.I.showAirStationStartupBleInDeviceOverview)
            _deviceActionButton(
              context,
              icon: Icons.restart_alt,
              label: 'Startup (BLE) …'.i18n,
              enabled: device.state == BleDeviceState.connected,
              onPressed: device.state == BleDeviceState.connected
                  ? () => showAirStationStartupFlagsDialog(
                        context: context,
                        device: device,
                      )
                  : null,
            ),
          if (device.state == BleDeviceState.connected && _sdBleExportNonEmpty)
            _deviceActionButton(
              context,
              icon: Icons.download_outlined,
              label: 'SD-Import (BLE)'.i18n,
              onPressed: () => showAirStationSdBleImportFlow(context: context, device: device),
            ),
          _deviceActionButton(
            context,
            icon: Icons.delete,
            label: 'Gerät entfernen'.i18n,
            color: Theme.of(context).colorScheme.error,
            onPressed: () => _confirmDeleteDevice(context, device),
          ),
        ];
        return Wrap(spacing: 8, runSpacing: 4, children: actions);
      },
    );
  }

  void _confirmDeleteDevice(BuildContext context, BleDevice device) {
    showLDDialog(
      context,
      text: '${'Gerät'.i18n} ${device.displayName} ${'aus der Geräteliste entfernen?'.i18n}',
      title: 'Gerät löschen?'.i18n,
      icon: Icons.delete,
      actions: [
        LDDialogAction(label: 'Behalten'.i18n, filled: false),
        LDDialogAction(
          label: 'Löschen'.i18n,
          filled: true,
          onTap: () {
            getIt<DeviceManager>().deleteDevice(device);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
      color: Colors.red,
    );
  }

}
