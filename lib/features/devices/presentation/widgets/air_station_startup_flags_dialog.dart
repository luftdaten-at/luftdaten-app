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

  Future<void> _save() async {
    if (_cfg.uploadSdLogToDatahub) {
      if (!await _confirmSensitiveUpload()) return;
    }
    if (_cfg.clearSdCard) {
      if (!await _confirmClearSdCard()) return;
    }

    setState(() => _busy = true);
    try {
      final bytes = _cfg.toBytesStartupFlagsOnly();
      final ok =
          await getIt<BleController>().sendAirStationConfig(widget.device, bytes);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Startup-Flags konnten nicht gesendet werden.'.i18n)),
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
        SnackBar(content: Text('Startup-Flags gespeichert — Station neu starten.'.i18n)),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      logger.d('Startup flags dialog save: $e $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                  'Diese Schalter entsprechen TLV-Flags 21–25 (`startup.toml`). '
                          'Geschrieben wird per BLE während die Station läuft; die Firmware '
                          'wertet sie in der Regel erst beim nächsten Neustart aus. '
                          'Bitte danach neu starten bzw. Strom unterbrechen.'
                      .i18n,
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('RTC von NTP synchronisieren (21)'.i18n),
                value: _cfg.syncRtcFromNtp,
                onChanged:
                    _busy ? null : (v) => setState(() => _cfg.syncRtcFromNtp = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Modell aus Sensoren erkennen (22)'.i18n),
                value: _cfg.detectModelFromSensors,
                onChanged:
                    _busy ? null : (v) => setState(() => _cfg.detectModelFromSensors = v),
              ),
              ExpansionTile(
                initiallyExpanded: _cfg.uploadSdLogToDatahub || _cfg.clearSdCard,
                tilePadding: EdgeInsets.zero,
                title: Text('Sensibel / zerstörerisch (23–24)'.i18n),
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text('SD-Log zum Datahub hochladen (23)'.i18n),
                    subtitle: Text('Erfordert Bestätigung beim Speichern.'.i18n),
                    value: _cfg.uploadSdLogToDatahub,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _cfg.uploadSdLogToDatahub = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text('SD-Karte leeren (24)'.i18n),
                    subtitle: Text('Zerstörerisch — Bestätigung mit CLEAR.'.i18n),
                    value: _cfg.clearSdCard,
                    onChanged:
                        _busy ? null : (v) => setState(() => _cfg.clearSdCard = v),
                  ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Sensoren neu einlesen (25)'.i18n),
                value: _cfg.refreshSensors,
                onChanged: _busy ? null : (v) => setState(() => _cfg.refreshSensors = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text('Abbrechen'.i18n),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text('Speichern'.i18n),
        ),
      ],
    );
  }
}
