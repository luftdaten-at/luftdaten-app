import 'dart:io';

import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:luftdaten.at/controller/app_settings.dart';
import 'package:luftdaten.at/controller/device_info.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/page/get_app_page.dart';
import 'package:luftdaten.at/page/nearby_devices_debug_page.dart';
import 'package:luftdaten.at/page/settings_page.i18n.dart';
import 'package:luftdaten.at/page/welcome_page.dart';
import 'package:luftdaten.at/widget/ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/ble_device.dart';
import 'licenses_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const String route = 'settings';

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Einstellungen'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpansionTile(
                  title: Text(
                    'Generell'.i18n,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _settingsSwitchRow(
                        title: 'Wakelock'.i18n,
                        desc: 'Bildschirm während Messung nicht ausschalten.'.i18n,
                        value: AppSettings.I.wakelock,
                        onChanged: (val) => setState(() => AppSettings.I.wakelock = val)),
                    _spacer(),
                    _settingsDropdownRow(
                      title: 'Sprache'.i18n,
                      value: (locale ?? I18n.of(context).locale.languageCode).toUpperCase(),
                      options: ['DE', 'EN'],
                      onSelected: (val) {
                        locale = val;
                        I18n.of(context).locale = Locale(locale!);
                        SharedPreferences.getInstance()
                            .then((sharedPref) => sharedPref.setString('locale', locale!));
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Dashboard'.i18n,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _settingsSwitchRow(
                        title: 'Reiter Air-Station-Geräte'.i18n,
                        value: AppSettings.I.dashboardShowAirStations,
                        onChanged: (val) => setState(() => AppSettings.I.dashboardShowAirStations = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Reiter Favoriten'.i18n,
                        value: AppSettings.I.dashboardShowFavorites,
                        onChanged: (val) => setState(() => AppSettings.I.dashboardShowFavorites = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Reiter tragbare Messgeräte'.i18n,
                        value: AppSettings.I.dashboardShowPortables,
                        onChanged: (val) => setState(() => AppSettings.I.dashboardShowPortables = val)),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Karte'.i18n,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _settingsSwitchRow(
                        title: 'Karte anzeigen'.i18n,
                        desc:
                            'Karte kann deaktiviert werden, um mobilen Datenverbrauch zu reduzieren.'
                                .i18n,
                        value: AppSettings.I.showMap,
                        onChanged: (val) => setState(() => AppSettings.I.showMap = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Stationäre Messstationen anzeigen'.i18n,
                        desc: 'Daten der sensor.community auf der Karte anzeigen.'.i18n,
                        value: AppSettings.I.showOverlay,
                        onChanged: (val) => setState(() => AppSettings.I.showOverlay = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Zoom-Icons'.i18n,
                        desc: 'Zoom-Icons auf der Karte anzeigen.'.i18n,
                        value: AppSettings.I.showZoomButtons,
                        onChanged: (val) => setState(() => AppSettings.I.showZoomButtons = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Kamera-Icon'.i18n,
                        desc: 'Kamera-Icon auf der Karte anzeigen.'.i18n,
                        value: AppSettings.I.showCameraButton,
                        onChanged: (val) => setState(() => AppSettings.I.showCameraButton = val),
                        beta: true),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Notiz-Icon'.i18n,
                        desc: 'Notiz-Icon auf der Karte anzeigen.'.i18n,
                        value: AppSettings.I.showNotesButton,
                        onChanged: (val) => setState(() => AppSettings.I.showNotesButton = val),
                        beta: true),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Karte autozentrieren'.i18n,
                        desc:
                            'Luftkarte während Messung automatisch auf deinen Standort zentrieren.'
                                .i18n,
                        value: AppSettings.I.followUserDuringMeasurements,
                        onChanged: (val) =>
                            setState(() => AppSettings.I.followUserDuringMeasurements = val)),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Messgeräte'.i18n,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _settingsSwitchRow(
                        title: 'Automatisch verbinden'.i18n,
                        desc:
                            'Automatische Verbindung für neue Messgeräte standardmäßig einschalten.'
                                .i18n,
                        value: AppSettings.I.defaultToAutoconnect,
                        onChanged: (val) =>
                            setState(() => AppSettings.I.defaultToAutoconnect = val)),
                    _spacer(),
                    _settingsButtonRow(
                        title: 'Alle Geräte löschen'.i18n,
                        onTap: () {
                          showLDDialog(
                            context,
                            content: Text(
                              'Alle gescannten Messgeräte aus der App entfernen?'.i18n,
                              textAlign: TextAlign.center,
                            ),
                            title: 'Alle Geräte löschen'.i18n,
                            icon: Icons.delete,
                            actions: [
                              LDDialogAction.cancel(),
                              LDDialogAction(
                                label: 'Löschen'.i18n,
                                onTap: () {
                                  DeviceManager deviceManager = getIt<DeviceManager>();
                                  for (BleDevice device in deviceManager.devices) {
                                    deviceManager.deleteDevice(device);
                                  }
                                },
                                filled: true,
                              ),
                            ],
                            color: Colors.red,
                          );
                        }),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Benachrichtigungen'.i18n,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _settingsSwitchRow(
                      title: 'WHO-Grenzwerte-Benachrichtigung'.i18n,
                      desc: 'Bei Überschreiten der WHO-Grenzwerte für Feinstaub benachrichtigen.'
                          .i18n,
                      value: AppSettings.I.sendNotificationOnExceededThreshold,
                      onChanged: (val) => setState(
                        () {
                          AppSettings.I.sendNotificationOnExceededThreshold = val;
                          if (!AppSettings.I.sendNotificationOnExceededThreshold) {
                            AppSettings.I.vibrateOnExceededThreshold = false;
                          }
                        },
                      ),
                    ),
                    _spacer(),
                    _settingsSwitchRow(
                      title: 'Vibrieren'.i18n,
                      desc: 'Bei Überschreiten der WHO-Grenzwerte für Feinstaub vibrieren.'.i18n,
                      value: AppSettings.I.vibrateOnExceededThreshold,
                      onChanged: (val) => setState(
                        () {
                          AppSettings.I.vibrateOnExceededThreshold = val;
                          if (AppSettings.I.vibrateOnExceededThreshold) {
                            AppSettings.I.sendNotificationOnExceededThreshold = true;
                          }
                        },
                      ),
                      beta: true,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Messungs-Einstellungen'.i18n,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _settingsSwitchRow(
                        title: 'Standort aufzeichnen'.i18n,
                        desc: 'Ortungsdaten zu Messpunkten hinzufügen.'.i18n,
                        value: AppSettings.I.recordLocation,
                        onChanged: (val) => setState(() => AppSettings.I.recordLocation = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Mit mehreren Geräten messen'.i18n,
                        desc: 'Auswahl mehrerer Geräte für gleichzeitige Messungen erlauben.'.i18n,
                        value: AppSettings.I.enableMultiDeviceMeasurements,
                        beta: true,
                        onChanged: (val) => setState(() => AppSettings.I.enableMultiDeviceMeasurements = val)),
                    _spacer(),
                    _settingsInfoRow(
                        title: 'Nur folgende Werte messen:'.i18n,
                        desc: '(Sofern von Messgerät untersützt)'.i18n),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'PM1.0 (μg/m³)'.i18n,
                        desc: 'Feinstaub mit Durchmesser unter 1,0 μm.'.i18n,
                        value: AppSettings.I.measurePM1,
                        onChanged: (val) => setState(() => AppSettings.I.measurePM1 = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'PM2.5 (μg/m³)'.i18n,
                        desc: 'Feinstaub mit Durchmesser unter 2,5 μm.'.i18n,
                        value: AppSettings.I.measurePM25,
                        onChanged: (val) => setState(() => AppSettings.I.measurePM25 = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'PM4.0 (μg/m³)'.i18n,
                        desc: 'Feinstaub mit Durchmesser unter 4,0 μm.'.i18n,
                        value: AppSettings.I.measurePM4,
                        onChanged: (val) => setState(() => AppSettings.I.measurePM4 = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'PM10.0 (μg/m³)'.i18n,
                        desc: 'Feinstaub mit Durchmesser unter 10,0 μm.'.i18n,
                        value: AppSettings.I.measurePM10,
                        onChanged: (val) => setState(() => AppSettings.I.measurePM10 = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Temperatur (°C)'.i18n,
                        value: AppSettings.I.measureTemp,
                        onChanged: (val) => setState(() => AppSettings.I.measureTemp = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Relative Luftfeuchtigkeit (%)'.i18n,
                        value: AppSettings.I.measureHumidity,
                        onChanged: (val) => setState(() => AppSettings.I.measureHumidity = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'VOC (Index)'.i18n,
                        desc: 'Flüchtige organische Verbindungen.'.i18n,
                        value: AppSettings.I.measureVOC,
                        onChanged: (val) => setState(() => AppSettings.I.measureVOC = val),
                        onInfoTapped: () {
                          showLDDialog(
                            context,
                            content: Text(
                                'Der VOC-Index beschreibt die aktuelle VOC-Belastung relativ zum Mittelwert der letzten 24 Stunden in Prozent.'
                                    .i18n,
                                textAlign: TextAlign.center),
                            title: 'VOC-Index'.i18n,
                            icon: Icons.info_outline,
                            actions: [
                              LDDialogAction(
                                label: 'Mehr Details'.i18n,
                                onTap: () => launchUrl(Uri.parse(
                                    'https://sensirion.com/media/documents/02232963/6294E043/Info_Note_VOC_Index.pdf')),
                                filled: false,
                              ),
                              LDDialogAction.dismiss(filled: true),
                            ],
                          );
                        }),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'NOX (Index)'.i18n,
                        desc: 'Stickoxide.'.i18n,
                        value: AppSettings.I.measureNOX,
                        onChanged: (val) => setState(() => AppSettings.I.measureNOX = val),
                        onInfoTapped: () {
                          showLDDialog(
                            context,
                            content: Text(
                                'Der NOX-Index beschreibt die aktuelle NOX-Belastung relativ zum Mittelwert der letzten 24 Stunden in Prozent.'
                                    .i18n,
                                textAlign: TextAlign.center),
                            title: 'NOX-Index'.i18n,
                            icon: Icons.info_outline,
                            actions: [
                              LDDialogAction(
                                label: 'Mehr Details'.i18n,
                                onTap: () => launchUrl(Uri.parse(
                                    'https://sensirion.com/media/documents/9F289B95/6294DFFC/Info_Note_NOx_Index.pdf')),
                                filled: false,
                              ),
                              LDDialogAction.dismiss(filled: true),
                            ],
                          );
                        }),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Luftdruck (hPa)'.i18n,
                        value: AppSettings.I.measurePressure,
                        onChanged: (val) => setState(() => AppSettings.I.measurePressure = val)),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Über App'.i18n,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _settingsInfoRow(
                        title: 'App-Version'.i18n,
                        desc:
                            '$appVersion ($buildNumber) ${'für'.i18n} ${Platform.isAndroid ? 'Android' : 'iOS'}.'),
                    _spacer(),
                    _settingsButtonRow(
                      title: 'Datenschutzerklärung'.i18n,
                      onTap: () => launchUrl(Uri.parse('https://luftdaten.at/datenschutz')),
                    ),
                    _spacer(),
                    _settingsButtonRow(
                      title: 'OpenStreetMap-Lizenz'.i18n,
                      desc: 'Wir verwenden OpenStreetMap für die Luftkarte.'.i18n,
                      onTap: () =>
                          launchUrl(Uri.parse('https://www.openstreetmap.org/copyright/de')),
                    ),
                    _spacer(),
                    _settingsButtonRow(
                      title: 'Package-Lizenzen'.i18n,
                      onTap: () => Navigator.of(context).pushNamed(LicensesPage.route),
                    ),
                    _spacer(),
                    _settingsButtonRow(
                      title: 'Kontakt'.i18n,
                      onTap: () => launchUrl(Uri.parse('https://luftdaten.at/kontakt')),
                    ),
                    _spacer(),
                    _settingsButtonRow(
                      title: 'App Download-Link anzeigen'.i18n,
                      onTap: () => Navigator.of(context).pushNamed(GetAppPage.route),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Entwickleroptionen'.i18n,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _settingsInfoRow(
                      title: 'Systemversion'.i18n,
                      desc: DeviceInfo.summaryString,
                    ),
                    _spacer(),
                    _settingsButtonRow(
                      title: 'Berechtigungen prüfen'.i18n,
                      onTap: () async {
                        _PermissionStatus location = _PermissionStatus.denied;
                        _PermissionStatus bluetooth = _PermissionStatus.denied;
                        if (await Permission.locationAlways.isGranted) {
                          location = _PermissionStatus.always;
                        } else if (await Permission.locationWhenInUse.isGranted ||
                            await Permission.location.isGranted) {
                          location = _PermissionStatus.whileInUse;
                        }
                        if (await Permission.bluetooth.isGranted ||
                            await Permission.bluetoothScan.isGranted) {
                          bluetooth = _PermissionStatus.allowed;
                        }
                        if (!context.mounted) {
                          return;
                        }
                        showLDDialog(
                          context,
                          title: 'Berechtigungsstatus'.i18n,
                          icon: Icons.info,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Standort'.i18n,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  _iconForPermissionStatus(location),
                                  const SizedBox(width: 5),
                                  Text(_textForPermissionStatus(location)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Bluetooth/Geräte in der Nähe'.i18n,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  _iconForPermissionStatus(bluetooth),
                                  const SizedBox(width: 5),
                                  Text(_textForPermissionStatus(bluetooth)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Log-Konsole'.i18n,
                        value: AppSettings.I.useLog,
                        onChanged: (val) => setState(() => AppSettings.I.useLog = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Serielle BLE-Konsole'.i18n,
                        value: AppSettings.I.showSerialMonitor,
                        onChanged: (val) => setState(() => AppSettings.I.showSerialMonitor = val)),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Staging-Server verwenden'.i18n,
                        value: AppSettings.I.useStagingServer,
                        onChanged: (val) => setState(() => AppSettings.I.useStagingServer = val)),
                    _spacer(),
                    _settingsButtonRow(
                      title: 'Willkommensbildschirm öffnen'.i18n,
                      onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(WelcomePage.route, (_) => false),
                    ),
                    _spacer(),
                    _settingsButtonRow(
                        title: 'BLE-Geräte in der Nähe'.i18n,
                        desc: 'Nach Luftdaten.at-Geräten in der Nähe suchen.'.i18n,
                        onTap: () {
                          Navigator.of(context).pushNamed(NearbyDevicesDebugPage.route);
                        },
                    ),
                    _spacer(),
                    _settingsButtonRow(
                        title: 'Daten exportieren'.i18n,
                        desc: 'Messdaten, Geräte- und Appeinstellungen exportieren.'.i18n,
                        onTap: () {} // TODO
                        ),
                    _spacer(),
                    _settingsSwitchRow(
                        title: 'Batteriedaten'.i18n,
                        desc: 'Batteriedaten auf Messwerte-Seite anzeigen'.i18n,
                        value: AppSettings.I.showBatteryGraph,
                        onChanged: (val) => setState(() => AppSettings.I.showBatteryGraph = val)),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsSwitchRow({
    required String title,
    String? desc,
    required bool value,
    required void Function(bool) onChanged,
    void Function()? onInfoTapped,
    bool beta = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (beta) const SizedBox(width: 5),
                  if (beta)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceTint,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                          child: Text(
                            'beta',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (desc != null)
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12),
                )
            ],
          ),
        ),
        if (onInfoTapped == null) const SizedBox(width: 20),
        if (onInfoTapped != null)
          IconButton(
            onPressed: onInfoTapped,
            icon: const Icon(Icons.info_outline, color: Colors.grey),
          ),
        Switch(
          value: value,
          onChanged: (bool value) => onChanged(value),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _settingsButtonRow({
    required String title,
    String? desc,
    required void Function() onTap,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 16, height: 42),
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
            const SizedBox(width: 20),
          ],
        ),
      ),
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

  Widget _settingsInfoRow({
    required String title,
    String? desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 16, height: 42),
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
        const SizedBox(width: 20),
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

  Widget _iconForPermissionStatus(_PermissionStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case _PermissionStatus.always:
      case _PermissionStatus.allowed:
        color = Colors.green;
        icon = Icons.check;
        break;
      case _PermissionStatus.whileInUse:
        color = Colors.orange;
        icon = Icons.circle_outlined;
        break;
      case _PermissionStatus.denied:
        color = Colors.red;
        icon = Icons.close;
        break;
    }
    return Icon(icon, color: color, size: 18);
  }

  String _textForPermissionStatus(_PermissionStatus status) {
    switch (status) {
      case _PermissionStatus.always:
        return 'Immer erlaubt'.i18n;
      case _PermissionStatus.allowed:
        return 'Erlaubt'.i18n;
      case _PermissionStatus.whileInUse:
        return 'Erlaubt, während App geöffnet ist'.i18n;
      case _PermissionStatus.denied:
        return 'Nicht erlaubt'.i18n;
    }
  }
}

enum _PermissionStatus { denied, whileInUse, always, allowed }
