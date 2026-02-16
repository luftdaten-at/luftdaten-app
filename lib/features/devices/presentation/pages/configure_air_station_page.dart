import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:luftdaten.at/core/core.dart';
import 'configure_air_station_page.i18n.dart';

class ConfigureAirStationPage extends StatefulWidget {
  const ConfigureAirStationPage(this.device, {super.key});

  final BleDevice device;

  @override
  State<StatefulWidget> createState() => _ConfigureAirStationPageState();
}

class _ConfigureAirStationPageState extends State<ConfigureAirStationPage> {
  AutoUpdateMode autoUpdateMode = AutoUpdateMode.on;
  BatterySaverMode batterySaverMode = BatterySaverMode.normal;

  AirStationMeasurementInterval measurementInterval = AirStationMeasurementInterval.min15;

  TextEditingController wifiSsid = TextEditingController();
  TextEditingController wifiPassword = TextEditingController();

  bool? configureWifi = true;

  _PageState pageState = _PageState.attemptingConnection;

  @override
  void initState() {
    NetworkInfo().getWifiName().then((value) => wifiSsid.text = value?.replaceAll('"', '') ?? '');
    widget.device.addListener(checkConnectionStatusAndSetState);
    checkConnectionStatusAndSetState(false);
    if (widget.device.state != BleDeviceState.connected) {
      attemptConnection(false);
    }
    super.initState();
  }

  void attemptConnection([bool doSetState = true]) async {
    if (widget.device.state == BleDeviceState.connected) return;
    pageState = _PageState.attemptingConnection;
    if (doSetState) setState(() {});
    getIt<DeviceManager>().scanForDevices(2000);
    await Future.delayed(const Duration(seconds: 2));
    if (widget.device.bleId != null) {
      widget.device.connect();
      await Future.delayed(const Duration(seconds: 2));
      if (widget.device.state != BleDeviceState.connected) {
        setState(() {
          pageState = _PageState.connectionFailed;
        });
      }
    } else {
      setState(() {
        pageState = _PageState.connectionFailed;
      });
    }
  }

  void checkConnectionStatusAndSetState([bool doSetState = true]) {
    if (widget.device.state == BleDeviceState.connected) {
      if (pageState == _PageState.attemptingConnection ||
          pageState == _PageState.connectionFailed) {
        pageState = _PageState.loadingConfig;
        if (doSetState) {
          // This prevents calling setState in initState
          setState(() {});
        }
        // Load current config from device
        getIt<BleController>().readAirStationConfiguration(widget.device).then((bytes) {
          logger.d('Received Air Station config: $bytes');
          logger.d('(length ${bytes!.length})');
          // Parse this configuration to set up the config screen
          int initialOffset = bytes[0] + 1;
          int settingsByte = bytes[initialOffset];
          autoUpdateMode = AutoUpdateMode.parseBinary(settingsByte >> 2);
          batterySaverMode = BatterySaverMode.parseBinary(settingsByte & 3);
          logger.d(
              'Measurement interval (secs): ${bytes[initialOffset + 2] << 8 | bytes[initialOffset + 3]}');
          measurementInterval = AirStationMeasurementInterval.parseSeconds(
              bytes[initialOffset + 2] << 8 | bytes[initialOffset + 3]);
          //logger.d('About to decode SSID');
          //String ssid = utf8.decode(bytes.sublist(initialOffset + 5), allowMalformed: true);
          //logger.d('Found WiFi SSID $ssid');
          //if(ssid.isNotEmpty) {
          //  wifiSsid.text = ssid;
          //}
          setState(() {
            pageState = _PageState.enterConfig;
          });
        });
      }
    } else {
      // TODO do we need to handle accidental disconnects as well?
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Air Station Konfiguration'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (pageState) {
      case _PageState.attemptingConnection:
        return _buildAttemptingConnection();
      case _PageState.connectionFailed:
        return _buildConnectionFailed();
      case _PageState.loadingConfig:
        return _buildLoadingConfig();
      case _PageState.enterConfig:
        return _buildEnterConfig();
      case _PageState.sending:
        return _buildSending();
    }
  }

  Widget _buildAttemptingConnection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        SpinKitDualRing(
          color: Theme.of(context).primaryColor,
          lineWidth: 4,
          duration: const Duration(milliseconds: 800),
        ),
        const SizedBox(height: 30),
        Text('Verbinde zu Gerät...'.i18n),
      ],
    );
  }

  Widget _buildLoadingConfig() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        SpinKitDualRing(
          color: Theme.of(context).primaryColor,
          lineWidth: 4,
          duration: const Duration(milliseconds: 800),
        ),
        const SizedBox(height: 30),
        Text('Lade Konfiguration von Gerät...'.i18n),
      ],
    );
  }

  Widget _buildSending() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        SpinKitDualRing(
          color: Theme.of(context).primaryColor,
          lineWidth: 4,
          duration: const Duration(milliseconds: 800),
        ),
        const SizedBox(height: 30),
        Text('Konfiguration wird übermittelt...'.i18n),
      ],
    );
  }

  Widget _buildConnectionFailed() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.nearby_error, color: Colors.red, size: 50),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Verbindung fehlgeschlagen'.i18n),
          ],
        ),
        // TODO make this screen prettier
        Text('Um dich mit der Station zu verbinden, stelle sicher, dass:'.i18n),
        Text('• Bluetooth auf deinem Mobilgerät eingeschalten ist.'.i18n),
        Text(
            '• Die Air Station im Konfigurations-Modus ist (erkenntlich durch die blau leuchtende Status-LED). Dieser wird mit dem BT-Button am Gerät aktiviert.'
                .i18n),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            attemptConnection();
          },
          child: Text('Erneut versuchen'.i18n),
        ),
      ],
    );
  }

  Widget _buildEnterConfig() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Einstellungen'.i18n,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        _settingsDropdownRow(
          title: 'Automatische Updates über Wifi'.i18n,
          value: autoUpdateMode.toString(),
          options: AutoUpdateMode.values.map((e) => e.toString()).toList(),
          onSelected: (val) {
            setState(() {
              autoUpdateMode = AutoUpdateMode.parseString(val);
            });
          },
        ),
        _spacer(),
        _settingsDropdownRow(
          title: 'Energiesparmodus'.i18n,
          value: batterySaverMode.toString(),
          options: BatterySaverMode.values.map((e) => e.toString()).toList(),
          onSelected: (val) {
            setState(() {
              batterySaverMode = BatterySaverMode.parseString(val);
            });
          },
        ),
        _spacer(),
        // TODO allow for entering a custom interval
        _settingsDropdownRow(
          title: 'Messintervall'.i18n,
          desc: 'Messen jede'.i18n,
          value: measurementInterval.toString(),
          options: AirStationMeasurementInterval.values.map((e) => e.toString()).toList(),
          onSelected: (val) {
            setState(() {
              measurementInterval = AirStationMeasurementInterval.parseString(val);
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Wifi-Zugangsdaten'.i18n,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Expanded(
                child: Text(
              'Aus Sicherheitsgründen werden gespeicherte Wifi-Passwörter nicht angezeigt.'.i18n,
            )),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
                child: Text(
              'Möchtest du die Station mit einem neuen Wifi-Netzwerk verbinden?'.i18n,
            )),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Spacer(flex: 1),
            SegmentedButton(
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: true, label: Text('Ja'.i18n)),
                ButtonSegment(value: false, label: Text('Nein'.i18n)),
              ],
              selected: configureWifi == null ? {} : {configureWifi},
              multiSelectionEnabled: false,
              onSelectionChanged: (selection) {
                setState(() {
                  configureWifi = selection.firstOrNull;
                });
              },
            ),
            const Spacer(flex: 1),
          ],
        ),
        if (configureWifi ?? false)
          TextField(
            controller: wifiSsid,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              labelText: 'SSID (Netzwerkname)'.i18n,
            ),
          ),
        if (configureWifi ?? false) const SizedBox(height: 5),
        if (configureWifi ?? false)
          TextField(
            controller: wifiPassword,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              labelText: 'Passwort'.i18n,
            ),
          ),
        const SizedBox(height: 5),
        FilledButton(
          onPressed: () {
            sendConfig();
          },
          child: Text('Konfiguration senden'.i18n),
        ),
      ],
    );
  }

  Widget _settingsDropdownRow({
    required String title,
    String? desc,
    required String value,
    required List<String> options,
    required void Function(String) onSelected,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (desc != null)
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12),
                )
            ],
          ),
        ),
        DropdownButton(
          value: value,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (String? value) {
            if (value != null) {
              onSelected(value);
            }
          },
          underline: const SizedBox(),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _spacer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 17, height: 5),
        Expanded(child: Divider(height: 1, color: Colors.grey.shade300)),
        const SizedBox(width: 17),
      ],
    );
  }

  void sendConfig() async {
    if (configureWifi ?? false) {
      // First check that if wifi config is valid
      if (wifiSsid.text.isEmpty || wifiPassword.text.isEmpty) {
        showLDDialog(
          context,
          color: Colors.red,
          content: Text(
            'Bitte überprüfe deine Wifi-Daten-Eingaben.'.i18n,
            textAlign: TextAlign.center,
          ),
          title: 'Ungültige Wifi-Daten',
          icon: Icons.wifi_off,
        );
        return;
      }
    }
    setState(() {
      pageState = _PageState.sending;
    });
    List<int> bytes = [];
    // Byte 0: Protocol version
    bytes.add(1);
    // Byte 1: (Critical updates, all updates, ultra battery saver mode, battery saver mode)
    bytes.add(autoUpdateMode.encoded << 2 | batterySaverMode.encoded);
    // Byte 2: Placeholder empty byte
    bytes.add(0);
    // Bytes 3 & 4: Measurement interval as i16
    bytes.add(measurementInterval.seconds >> 8);
    bytes.add(measurementInterval.seconds & 0xff);
    // Bytes 5 to 32: placeholders for future config options
    for (int i = 0; i < 28; i++) {
      bytes.add(0);
    }
    // If wifi config given, add this as well
    if (configureWifi ?? false) {
      bytes.add(wifiSsid.text.length);
      bytes.add(0); // Flag for SSID
      bytes.addAll(utf8.encode(wifiSsid.text));
      bytes.add(wifiPassword.text.length);
      bytes.add(1); // Flag for password
      bytes.addAll(utf8.encode(wifiPassword.text));
    }
    try {
      bool success = await getIt<BleController>().sendAirStationConfig(widget.device, bytes);
      if (success) {
        setState(() {
          Navigator.of(context).pop(true);
        });
      } else {
        if (!mounted) return;
        setState(() {
          pageState = _PageState.enterConfig;
        });
        showLDDialog(
          context,
          color: Colors.red,
          content: Text(
            'Fehler während der Übermittlung.'.i18n,
            textAlign: TextAlign.center,
          ),
          title: 'Übermittlungsfehler',
          icon: Icons.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        pageState = _PageState.enterConfig;
      });
      showLDDialog(
        context,
        color: Colors.red,
        content: Text(
          'Die Konfiguration konnte nicht übermittelt werden. Bitte überprüfe deine Verbindung zur Air Station.'
              .i18n,
          textAlign: TextAlign.center,
        ),
        title: 'Übermittlungsfehler',
        icon: Icons.error,
      );
    }
  }

  @override
  void dispose() {
    widget.device.removeListener(checkConnectionStatusAndSetState);
    super.dispose();
  }
}

enum _PageState { attemptingConnection, connectionFailed, loadingConfig, enterConfig, sending }

enum AutoUpdateMode {
  on('An (Empfohlen)', 1 << 1 | 1),
  critical('Nur kritische', 1 << 1),
  off('Aus', 0);

  final String _name;
  final int encoded;

  const AutoUpdateMode(this._name, this.encoded);

  @override
  String toString() {
    return _name.i18n;
  }

  factory AutoUpdateMode.parseString(String name) {
    return AutoUpdateMode.values.where((e) => e.toString() == name).first;
  }

  factory AutoUpdateMode.parseBinary(int binary) {
    return AutoUpdateMode.values.where((e) => e.encoded == binary).firstOrNull ?? AutoUpdateMode.on;
  }
}

enum BatterySaverMode {
  ultra('Ultra', 1 << 1 | 1),
  normal('Normal (Empfohlen)', 1),
  off('Aus', 0);

  final String _name;
  final int encoded;

  const BatterySaverMode(this._name, this.encoded);

  @override
  String toString() {
    return _name.i18n;
  }

  factory BatterySaverMode.parseString(String name) {
    return BatterySaverMode.values.where((e) => e.toString() == name).first;
  }

  factory BatterySaverMode.parseBinary(int binary) {
    return BatterySaverMode.values.where((e) => e.encoded == binary).firstOrNull ??
        BatterySaverMode.normal;
  }
}

enum AirStationMeasurementInterval {
  sec30('30 Sekunden', 30),
  min1('1 Minute', 60),
  min3('3 Minuten', 180),
  min5('5 Minuten (Empfohlen)', 300),
  min10('10 Minuten', 600),
  min15('15 Minuten', 900),
  min30('30 Minuten', 1800),
  h1('1 Stunde', 3600);

  final String _name;
  final int seconds;

  const AirStationMeasurementInterval(this._name, this.seconds);

  @override
  String toString() {
    return _name.i18n;
  }

  factory AirStationMeasurementInterval.parseString(String name) {
    return AirStationMeasurementInterval.values.where((e) => e.toString() == name).first;
  }

  factory AirStationMeasurementInterval.parseSeconds(int seconds) {
    return AirStationMeasurementInterval.values.where((e) => e.seconds == seconds).firstOrNull ??
        AirStationMeasurementInterval.min5;
  }
}
