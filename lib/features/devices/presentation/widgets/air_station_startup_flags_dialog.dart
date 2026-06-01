import 'dart:async';

import 'package:flutter/material.dart';
import 'package:i18n_extension/default.i18n.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';

Future<void> showAirStationStartupFlagsDialog({
  required BuildContext context,
  required BleDevice device,
  AirStationConfig? preferExistingMutableConfig,
}) async {
  if (device.model != LDDeviceModel.station) {
    logger.d('Startup flags dialog: ignored non-station model=${device.model}');
    return;
  }
  if (device.state != BleDeviceState.connected) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Verbinde zuerst per Bluetooth mit der Air Station.'.i18n)),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => _AirStationStartupFlagsDialog(
      device: device,
      preferExistingMutableConfig: preferExistingMutableConfig,
    ),
  );
}

class _AirStationStartupFlagsDialog extends StatefulWidget {
  const _AirStationStartupFlagsDialog({
    required this.device,
    this.preferExistingMutableConfig,
  });

  final BleDevice device;
  final AirStationConfig? preferExistingMutableConfig;

  @override
  State<_AirStationStartupFlagsDialog> createState() =>
      _AirStationStartupFlagsDialogState();
}

class _AirStationStartupFlagsDialogState extends State<_AirStationStartupFlagsDialog> {
  bool _busy = false;
  late AirStationConfig _cfg;

  static const _setFlagAndRestartLabel = 'Set flag and restart';

  @override
  void initState() {
    super.initState();
    final id = widget.device.bleName;
    _cfg = widget.preferExistingMutableConfig ??
        AirStationConfigManager.getConfig(id) ??
        AirStationConfig.defaultConfig(id);
    unawaited(_bootstrapFromBle());
  }

  Future<void> _bootstrapFromBle() async {
    try {
      List<int>? raw;
      try {
        raw = await getIt<BleController>().readAirStationConfiguration(widget.device);
      } catch (e, st) {
        logger.d('Startup flags dialog: BLE read failed: $e $st');
      }
      if (!mounted) return;
      if (raw != null && raw.isNotEmpty) {
        final snapshot = AirStationConfig.fromBytes(widget.device.bleName, raw);
        _cfg.applyNonSecretSnapshotFromBleRead(snapshot);
        setState(() {});
      }
    } catch (e, st) {
      logger.d('Startup flags dialog bootstrap: $e $st');
    }
  }

  Future<bool> _confirmSensitiveUpload() async {
    final ctx = context;
    final r = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text('SD-Log zum Datahub?'.i18n),
        content: Text(
          'TLV 23 aktiviert einen sensiblen Vorgang (Upload von SD-Logs zum Datahub). '
                  'Die Station muss danach neu starten. Fortfahren?'
              .i18n,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text('Abbrechen'.i18n)),
          FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: Text('Fortfahren'.i18n)),
        ],
      ),
    );
    return r ?? false;
  }

  Future<bool> _confirmClearSdCard() async {
    final ctx = context;
    final ctl = TextEditingController();
    try {
      final r = await showDialog<bool>(
        context: ctx,
        barrierDismissible: false,
        builder: (dCtx) => AlertDialog(
          title: Text('SD-Karte leeren?'.i18n),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TLV 24 ist zerstörerisch: Daten auf der SD-Karte können gelöscht werden. '
                        'Trenne die Verbindung und starte die Station nach dem Schreiben neu. '
                        'Zur Bestätigung tippe CLEAR (Großbuchstaben).'
                    .i18n,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Bestätigung'.i18n,
                  hintText: 'CLEAR',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: Text('Abbrechen'.i18n),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final ok = ctl.text.trim() == 'CLEAR';
                Navigator.pop(dCtx, ok);
              },
              child: Text('Löschen aktivieren'.i18n),
            ),
          ],
        ),
      );
      return r ?? false;
    } finally {
      ctl.dispose();
    }
  }

  Future<bool> _confirmGateForFlag(AirStationConfigFlags flag) async {
    switch (flag) {
      case AirStationConfigFlags.UPLOAD_SD_LOG_TO_DATAHUB:
        return _confirmSensitiveUpload();
      case AirStationConfigFlags.CLEAR_SD_CARD:
        return _confirmClearSdCard();
      default:
        return true;
    }
  }

  Future<void> _sendStartupFlag(AirStationConfigFlags flag) async {
    if (_busy) return;
    if (!await _confirmGateForFlag(flag)) return;

    setState(() => _busy = true);
    try {
      final bytes = _cfg.toBytesStartupSingleFlagTlv(flag);
      final ok =
          await getIt<BleController>().sendAirStationConfig(widget.device, bytes);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Startup-Flag konnte nicht gesendet werden.'.i18n)),
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 450));

      try {
        final raw =
            await getIt<BleController>().readAirStationConfiguration(widget.device);
        if (raw != null && raw.isNotEmpty) {
          final snapshot = AirStationConfig.fromBytes(widget.device.bleName, raw);
          _cfg.applyNonSecretSnapshotFromBleRead(snapshot);
        }
      } catch (e, st) {
        logger.d('Startup flags dialog: read-back failed: $e $st');
      }

      await _cfg.persist();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Flag gesetzt — Station neu starten.'.i18n)),
      );
      setState(() {});
    } catch (e, st) {
      logger.d('Startup flags dialog send flag: $e $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _actionBlock({
    required String title,
    String? subtitle,
    required AirStationConfigFlags flag,
    Color? buttonColor,
  }) {
    final style = buttonColor != null
        ? FilledButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
          )
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.secondary),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            style: style,
            onPressed: _busy ? null : () => unawaited(_sendStartupFlag(flag)),
            child: Text(_setFlagAndRestartLabel.i18n),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Startup (BLE)'.i18n),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Mit jedem Knopf wird nur das zugehörige TLV (21, 23–25) per BLE geschrieben '
                          '(`startup.toml`); die Firmware nutzt es in der Regel erst nach einem '
                          'Neustart. TLV 22 wird in dieser Ansicht nicht angeboten — bei Bedarf '
                          'über USB / `startup.toml`.'
                      .i18n,
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13),
                ),
              ),
              _actionBlock(
                title: 'RTC von NTP synchronisieren (TLV 21)'.i18n,
                subtitle:
                    'Nach dem Schreiben Bluetooth trennen und Station neu starten.'.i18n,
                flag: AirStationConfigFlags.SYNC_RTC_FROM_NTP,
              ),
              const Divider(height: 24),
              Text('Sensibel / zerstörerisch'.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _actionBlock(
                title: 'SD-Log zum Datahub hochladen (TLV 23)'.i18n,
                subtitle: 'Sensibel — Bestätigung vor dem Senden.'.i18n,
                flag: AirStationConfigFlags.UPLOAD_SD_LOG_TO_DATAHUB,
                buttonColor: Colors.deepOrange.shade800,
              ),
              _actionBlock(
                title: 'SD-Karte leeren (TLV 24)'.i18n,
                subtitle: 'Zerstörerisch — Bestätigung mit CLEAR.'.i18n,
                flag: AirStationConfigFlags.CLEAR_SD_CARD,
                buttonColor: Colors.red.shade700,
              ),
              const Divider(height: 24),
              _actionBlock(
                title: 'Sensoren neu einlesen (TLV 25)'.i18n,
                subtitle:
                    'Nach dem Schreiben Bluetooth trennen und Station neu starten.'.i18n,
                flag: AirStationConfigFlags.REFRESH_SENSORS,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text('Schließen'.i18n),
        ),
      ],
    );
  }
}
