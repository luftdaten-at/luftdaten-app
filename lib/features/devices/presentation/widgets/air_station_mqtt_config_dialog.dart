import 'dart:async';

import 'package:flutter/material.dart';
import 'package:i18n_extension/default.i18n.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/station_secrets_store.dart';

/// TLV flags `9…17` for MQTT/Home Assistant surfaced in firmware MQTT BLE docs.
///
/// Tune when MQTT-over-BLE is tied to a specific release tag; until then `{0.0.0}`
/// skips the banner and unknown versions skip it too.
abstract final class _AirStationMqttBleFirmwareGate {
  static const FirmwareVersion minimumKnownMqttTlv = FirmwareVersion(1, 10, 0);
}

Future<void> showAirStationMqttConfigDialog({
  required BuildContext context,
  required BleDevice device,
  AirStationConfig? preferExistingMutableConfig,
}) async {
  if (device.model != LDDeviceModel.station) {
    logger.d('MQTT dialog: ignored non-station device model=${device.model}');
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
    builder: (ctx) => _AirStationMqttConfigDialog(
      device: device,
      preferExistingMutableConfig: preferExistingMutableConfig,
    ),
  );
}

class _AirStationMqttConfigDialog extends StatefulWidget {
  const _AirStationMqttConfigDialog({
    required this.device,
    this.preferExistingMutableConfig,
  });

  final BleDevice device;

  /// When non-null (e.g. wizard), MQTT edits persist the same mutable instance already held by callers.
  final AirStationConfig? preferExistingMutableConfig;

  @override
  State<_AirStationMqttConfigDialog> createState() =>
      _AirStationMqttConfigDialogState();
}

class _AirStationMqttConfigDialogState extends State<_AirStationMqttConfigDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _obscurePassword = true;
  bool _mqttPasswordEdited = false;
  bool _portEditedByUser = false;
  bool _hasStoredMqttPassword = false;

  late AirStationConfig _cfg;

  late final TextEditingController _brokerCtl;
  late final TextEditingController _portCtl;
  late final TextEditingController _userCtl;
  late final TextEditingController _pwCtl;
  late final TextEditingController _discoveryCtl;
  late final TextEditingController _deviceNameCtl;
  late final TextEditingController _certPathCtl;

  @override
  void initState() {
    super.initState();

    final id = widget.device.bleName;
    _cfg = widget.preferExistingMutableConfig ??
        AirStationConfigManager.getConfig(id) ??
        AirStationConfig.defaultConfig(id);

    _brokerCtl = TextEditingController(text: _cfg.mqttBroker ?? '');
    _portCtl = TextEditingController(text: _cfg.mqttPort.toString());
    _userCtl = TextEditingController(text: _cfg.mqttUsername ?? '');
    _pwCtl = TextEditingController();

    final disc =
        (_cfg.mqttDiscoveryPrefix?.trim().isNotEmpty ?? false)
            ? _cfg.mqttDiscoveryPrefix!.trim()
            : AirStationBleHomeAssistantDefaults.mqttDiscoveryPrefix;
    _discoveryCtl = TextEditingController(text: disc);
    _deviceNameCtl = TextEditingController(text: _cfg.mqttDeviceName ?? '');
    _certPathCtl = TextEditingController(text: _cfg.mqttCertificatePath ?? '');

    _portEditedByUser = false;

    unawaited(_bootstrapFromBleAndSecrets());
  }

  Future<void> _bootstrapFromBleAndSecrets() async {
    try {
      final stored = await StationSecretsStore.instance.readMqttPassword(widget.device.bleName);
      final hasPw = stored != null && stored.isNotEmpty;
      if (!mounted) return;

      List<int>? raw;
      try {
        raw = await getIt<BleController>().readAirStationConfiguration(widget.device);
      } catch (e, st) {
        logger.d('MQTT dialog: BLE read air_station_configuration failed: $e $st');
      }
      if (!mounted) return;

      if (raw != null && raw.isNotEmpty) {
        final snapshot = AirStationConfig.parseFromBytes(widget.device.bleName, raw);
        _cfg.applyNonSecretSnapshotFromBleRead(snapshot);
        _brokerCtl.text = _cfg.mqttBroker ?? '';
        _portCtl.text = _cfg.mqttPort.toString();
        _userCtl.text = _cfg.mqttUsername ?? '';
        final d = (_cfg.mqttDiscoveryPrefix?.trim().isNotEmpty ?? false)
            ? _cfg.mqttDiscoveryPrefix!.trim()
            : AirStationBleHomeAssistantDefaults.mqttDiscoveryPrefix;
        _discoveryCtl.text = d;
        _deviceNameCtl.text = _cfg.mqttDeviceName ?? '';
        _certPathCtl.text = _cfg.mqttCertificatePath ?? '';
        _pwCtl.clear();
      }

      setState(() {
        _hasStoredMqttPassword = hasPw;
        _mqttPasswordEdited = false;
      });
    } catch (e, st) {
      logger.d('MQTT dialog bootstrap failed: $e $st');
    }
  }

  bool _showsFirmwareLikelyUnsupportedBanner() {
    final v = widget.device.firmwareVersion;
    if (v == null || v.isUnsetPlaceholder) return false;
    return v.isOlderThan(_AirStationMqttBleFirmwareGate.minimumKnownMqttTlv);
  }

  void _onTlsChanged(bool v) {
    setState(() {
      _cfg.mqttUseTls = v;
      if (!_portEditedByUser) {
        _cfg.mqttPort =
            v ? AirStationBleHomeAssistantDefaults.mqttPortTls : AirStationBleHomeAssistantDefaults.mqttPortPlain;
        _portCtl.text = _cfg.mqttPort.toString();
      }
    });
  }

  String? _validateBroker(String? s) {
    if (!_cfg.mqttEnabled) return null;
    final t = (s ?? '').trim();
    if (t.isEmpty) return 'Broker ist erforderlich.'.i18n;
    if (t.contains(RegExp(r'\s'))) return 'Hostname darf keine Leerzeichen enthalten.'.i18n;
    return null;
  }

  String? _validatePort(String? s) {
    if (!_cfg.mqttEnabled) return null;
    final t = (s ?? '').trim();
    final p = int.tryParse(t);
    if (p == null || p < 1 || p > 65535) return 'Port 1–65535.'.i18n;
    return null;
  }

  String? _validateDiscoveryPrefix(String? s) {
    if (!_cfg.mqttEnabled) return null;
    final t = (s ?? '').trim();
    if (t.isEmpty) return 'Discovery-Präfix darf nicht leer sein.'.i18n;
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      _cfg.mqttBroker = _brokerCtl.text.trim().isEmpty ? null : _brokerCtl.text.trim();
      _cfg.mqttPort = int.parse(_portCtl.text.trim());
      _cfg.mqttUsername = _userCtl.text.trim().isEmpty ? null : _userCtl.text.trim();
      final discTrim = _discoveryCtl.text.trim();
      _cfg.mqttDiscoveryPrefix =
          discTrim.isEmpty ? AirStationBleHomeAssistantDefaults.mqttDiscoveryPrefix : discTrim;
      _cfg.mqttDeviceName =
          _deviceNameCtl.text.trim().isEmpty ? null : _deviceNameCtl.text.trim();
      _cfg.mqttCertificatePath =
          _certPathCtl.text.trim().isEmpty ? null : _certPathCtl.text.trim();

      final pwTrimmed = _pwCtl.text.trim();
      final sendPwTlv = _mqttPasswordEdited && pwTrimmed.isNotEmpty;

      final bytes = _cfg.toBytesMqttOnly(
        appendMqttPasswordTlv14: sendPwTlv,
        mqttPasswordForTlv14: sendPwTlv ? pwTrimmed : null,
      );

      final ok = await getIt<BleController>().sendAirStationConfig(widget.device, bytes);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MQTT-Einstellungen konnten nicht gesendet werden.'.i18n)),
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 450));

      try {
        final raw = await getIt<BleController>().readAirStationConfiguration(widget.device);
        if (raw != null && raw.isNotEmpty) {
          final snapshot = AirStationConfig.parseFromBytes(widget.device.bleName, raw);
          _cfg.applyNonSecretSnapshotFromBleRead(snapshot);
        }
      } catch (e, st) {
        logger.d('MQTT dialog: post-save read-back failed: $e $st');
      }

      try {
        if (_mqttPasswordEdited) {
          if (pwTrimmed.isNotEmpty) {
            await StationSecretsStore.instance.writeMqttPassword(widget.device.bleName, pwTrimmed);
          } else {
            await StationSecretsStore.instance.deleteMqttPassword(widget.device.bleName);
          }
        }
      } catch (e, st) {
        logger.d('MQTT dialog: secure store password persist failed: $e $st');
      }

      await _cfg.persist(lastConfiguredAt: DateTime.now());

      final editedPw = _mqttPasswordEdited;
      if (editedPw) {
        _hasStoredMqttPassword = pwTrimmed.isNotEmpty;
      }
      _mqttPasswordEdited = false;
      _pwCtl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('MQTT-Einstellungen gespeichert.'.i18n)),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      logger.d('MQTT dialog save exception: $e $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _brokerCtl.dispose();
    _portCtl.dispose();
    _userCtl.dispose();
    _pwCtl.dispose();
    _discoveryCtl.dispose();
    _deviceNameCtl.dispose();
    _certPathCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('MQTT / Home Assistant (BLE)'.i18n),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showsFirmwareLikelyUnsupportedBanner())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Deine Firmware könnte MQTT über BLE noch nicht unterstützen — bitte ggf. '
                              'Firmware aktualisieren (MQTT TLV ab ca. ${_AirStationMqttBleFirmwareGate.minimumKnownMqttTlv}). '
                              'Für empfindliche Broker-Zugänge hilft zusätzliche Bluetooth-Kopplung (bonding).'
                          .i18n,
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('MQTT aktivieren'.i18n),
                  value: _cfg.mqttEnabled,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                            _cfg.mqttEnabled = v;
                          }),
                ),
                TextFormField(
                  controller: _brokerCtl,
                  enabled: !_busy,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'Broker (Hostname/IP)'.i18n),
                  validator: _validateBroker,
                ),
                TextFormField(
                  controller: _portCtl,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Port'.i18n),
                  onChanged: (_) {
                    _portEditedByUser = true;
                  },
                  validator: _validatePort,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('TLS aktivieren'.i18n),
                  subtitle: Text('Standardports: TLS 8883, ohne TLS 1883.'.i18n),
                  value: _cfg.mqttUseTls,
                  onChanged: _busy ? null : _onTlsChanged,
                ),
                TextFormField(
                  controller: _userCtl,
                  enabled: !_busy,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'Benutzername (optional)'.i18n),
                ),
                TextFormField(
                  controller: _pwCtl,
                  enabled: !_busy,
                  autocorrect: false,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'MQTT-Passwort'.i18n,
                    suffixIcon: IconButton(
                      tooltip: 'Ein-/Ausblenden'.i18n,
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    helperText:
                        ((_hasStoredMqttPassword && !_mqttPasswordEdited) || (_mqttPasswordEdited && _pwCtl.text.isEmpty))
                            ? 'Ein Passwort ist lokal gespeichert — nur bei Änderungen erneut senden.'.i18n
                            : 'Wird nur per BLE geschrieben wenn du es änderst; kommt nie im Read-back.'.i18n,
                  ),
                  onChanged: (_) {
                    _mqttPasswordEdited = true;
                    setState(() {});
                  },
                ),
                TextFormField(
                  controller: _discoveryCtl,
                  enabled: !_busy,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'Discovery-Präfix'.i18n),
                  validator: _validateDiscoveryPrefix,
                ),
                TextFormField(
                  controller: _deviceNameCtl,
                  enabled: !_busy,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'MQTT-Gerätename (optional)'.i18n),
                ),
                ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  title: Text('Erweitert: Zertifikatspfad auf Station'.i18n),
                  children: [
                    TextFormField(
                      controller: _certPathCtl,
                      enabled: !_busy,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'Leer lassen für Firmware‑Standard‑CA.'.i18n,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text('Abbrechen'.i18n)),
        FilledButton(onPressed: _busy ? null : _save, child: Text('Speichern'.i18n)),
      ],
    );
  }
}
