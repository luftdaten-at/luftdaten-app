import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:lottie/lottie.dart';
import 'package:luftdaten.at/controller/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/model/air_station_config.dart';
import 'package:luftdaten.at/model/ble_device.i18n.dart';
import 'package:luftdaten.at/util/list_extensions.dart';
import 'package:luftdaten.at/widget/change_notifier_builder.dart';
import 'package:luftdaten.at/widget/ui.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
import '../widget/ellipsis.dart';

class AirStationConfigWizardPage extends StatefulWidget {
  const AirStationConfigWizardPage({super.key, required this.controller});

  final AirStationConfigWizardController controller;

  @override
  State<AirStationConfigWizardPage> createState() => _AirStationConfigWizardPageState();
}

class _AirStationConfigWizardPageState extends State<AirStationConfigWizardPage>
    with TickerProviderStateMixin {
  late AnimationController animation;

  @override
  void initState() {
    animation = AnimationController(vsync: this)
      ..duration = const Duration(seconds: 3)
      ..forward()
      ..addListener(() {
        if (animation.isCompleted) {
          animation.repeat();
        }
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop(),
      onPopInvoked: (_) => onPop(),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title:
                Text('Air Station konfigurieren'.i18n, style: const TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).primaryColor,
            leading: IconButton(
              onPressed: () {
                if (canPop()) Navigator.of(context).pop();
                onPop();
              },
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),
          ),
          body: ChangeNotifierBuilder(
            notifier: widget.controller,
            builder: (_, __) => buildContent(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  Widget buildContent() {
    switch (widget.controller.stage) {
      case AirStationConfigWizardStage.verifyingDeviceState:
        return buildLoadingScreen('Überprüfe Einstellungen...');
      case AirStationConfigWizardStage.scanningForDevices:
        return buildLoadingScreen('Suche nach Geräten...');
      case AirStationConfigWizardStage.attemptingConnection:
        return buildLoadingScreen('Verbinde mit Gerät...');
      case AirStationConfigWizardStage.loadingConfig:
        return buildLoadingScreen('Lade Konfiguration...');
      case AirStationConfigWizardStage.sending:
        return buildLoadingScreen('Sende Konfiguration...');
      case AirStationConfigWizardStage.loadingStatus:
        return buildLoadingScreen('Lade Status...');
      case AirStationConfigWizardStage.deviceDoesNotSupportBLE:
        return buildInfoScreen(
          title: 'Dieses Gerät unterstützt Bluetooth nicht',
          body: ['Verwende ein anderes Gerät, um deine Air Station zu konfigurieren.'],
          buttons: [
            FilledButton(
              onPressed: () {
                AirStationConfigWizardController.removeController(widget.controller.id);
                Navigator.pop(context);
              },
              child: Text('Vorgang beenden'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.bluetoothTurnedOff:
        return buildInfoScreen(
          title: 'Bluetooth ist ausgeschaltet',
          body: [
            'Um deine Air Station zu konfigurieren, musst du die Bluetooth-Funktion auf '
                'deinem Mobilgerät aktivieren.',
            'Eine Kopplung („Pairing“) ist nicht notwending, da die Air Station Bluetooth Low '
                'Energy (BLE) verwendet.',
            'Wenn du Bluetooth bereits eingeschaltet hast, drücke auf „Erneut prüfen“.'
          ],
          icon: Icons.bluetooth_disabled,
          buttons: [
            FilledButton(
              onPressed: () {
                widget.controller.requestBluetoothPowerOn();
              },
              child: Text('Bluetooth aktivieren'.i18n),
            ),
            TextButton(
              onPressed: () {
                if (FlutterReactiveBle().status == BleStatus.poweredOff) {
                  showLDDialog(
                    context,
                    title: 'Bluetooth ausgeschaltet',
                    icon: Icons.bluetooth_disabled,
                    text:
                        'Bluetooth ist weiterhin ausgeschaltet. Schalte Bluetooth ein, um fortzufahren.',
                  );
                } else {
                  widget.controller.verifyDeviceState();
                }
              },
              child: Text('Erneut prüfen'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.blePermissionMissing:
        return buildInfoScreen(
          title: 'Berechtigung benötigt',
          body: [
            'Um deine Air Station zu konfigurieren, wird die Berechtigung „Geräte in der Nähe“ '
                'benötigt.',
            'Bitte erteile diese Berechtigung, um fortzufahren.',
          ],
          icon: Icons.nearby_error,
          buttons: [
            FilledButton(
              onPressed: () async {
                if (await Permission.bluetoothScan.isPermanentlyDenied) {
                  if (!mounted) return;
                  showLDDialog(
                    context,
                    title: 'Berechtigung permanent abgelehnt',
                    icon: Icons.error_outline,
                    text: 'Du hast diese Berechtigung zuvor permanent abgelehnt. Bitte erteile '
                        'manuell in deinen App-Einstellungen.',
                  );
                } else {
                  widget.controller.requestNearbyDevicesPermission();
                  widget.controller.requestGpsPermission();
                }
              },
              child: Text('Berechtigung anfragen'.i18n),
            ),
            TextButton(
              onPressed: () {
                if (FlutterReactiveBle().status == BleStatus.unauthorized) {
                  showLDDialog(
                    context,
                    title: 'Berechtigung abgelehnt',
                    icon: Icons.error_outline,
                    text: 'Die Berechtigung wurde noch nicht erteilt.',
                  );
                } else {
                  widget.controller.verifyDeviceState();
                }
              },
              child: Text('Erneut prüfen'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.gpsPermissionMissing:
        return buildInfoScreen(
          title: 'Berechtigung benötigt',
          body: [
            'Um deine Air Station zu konfigurieren, wird die Berechtigung „GPS“ '
                'benötigt.',
            'Bitte erteile diese Berechtigung, um fortzufahren.',
          ],
          icon: Icons.location_off,
          buttons: [
            FilledButton(
              onPressed: () async {
                if (await Permission.location.isPermanentlyDenied) {
                  if (!mounted) return;
                  showLDDialog(
                    context,
                    title: 'Berechtigung permanent abgelehnt',
                    icon: Icons.error_outline,
                    text: 'Du hast diese Berechtigung zuvor permanent abgelehnt. Bitte erteile '
                        'manuell in deinen App-Einstellungen.',
                  );
                } else {
                  widget.controller.requestGpsPermission();
                }
              },
              child: Text('Berechtigung anfragen'.i18n),
            ),
            TextButton(
              onPressed: () async {
                if (await Permission.location.status == PermissionStatus.denied) {
                  showLDDialog(
                    context,
                    title: 'Berechtigung abgelehnt',
                    icon: Icons.error_outline,
                    text: 'Die Berechtigung wurde noch nicht erteilt.',
                  );
                } else {
                  widget.controller.verifyDeviceState();
                }
              },
              child: Text('Erneut prüfen'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.scanFailed:
        return buildInfoScreen(
          title: 'Bluetooth-Scan fehlgeschlagen',
          body: [
            'Wir sind gerade nicht in der Lage, nach Bluetooth-Geräten zu suchen.',
            'Dies liegt oft an internen Fehlern des Betriebssystems. Versuche es später '
                'erneut oder verwende ein anderes Mobilgerät.',
          ],
          icon: Icons.bluetooth_disabled,
          buttons: [
            FilledButton(
              onPressed: () {
                AirStationConfigWizardController.removeController(widget.controller.id);
                Navigator.pop(context);
              },
              child: Text('Vorgang beenden'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.deviceNotVisible:
        return buildInfoScreen(
          title: 'Bluetooth auf deiner Air Station aktivieren',
          body: [
            'Stelle zunächst sicher, dass deine Air Station mit einem Netzteil mit mindestens '
                '2A Stromstärke verbunden ist.',
            'Drücke dann den „BT“-Knopf am Gerät. Die Status-LED neben dem Knopf sollte nun '
                'blau leuchten. Drücke dann auf „Weiter“.',
          ],
          icon: Icons.bluetooth,
          buttons: [
            FilledButton(
              onPressed: () {
                widget.controller.checkDeviceConnection();
              },
              child: Text('Weiter'.i18n),
            ),
            TextButton(
              onPressed: () {
                widget.controller.stage =
                    AirStationConfigWizardStage.deviceNotVisibleButBLEButtonBlue;
              },
              child: Text('LED war bereits blau'.i18n),
            ),
            TextButton(
              onPressed: () {
                widget.controller.stage =
                    AirStationConfigWizardStage.deviceNotVisibleAndBLEButtonNotBlue;
              },
              child: Text('LED schaltet sich nicht ein'.i18n),
            ),
            // TODO ist LED zeigt andere Farbe auch eine Option?
            // Wenn ja, sollte dies entfernt werden.
          ],
        );
      case AirStationConfigWizardStage.deviceNotVisibleButBLEButtonBlue:
        return buildInfoScreen(
          title: 'Gerät außer Reichweite',
          body: [
            'Bluetooth Low Energy hat eine geringe Reichweite. Stelle sicher, dass dein '
                'Mobilgerät in der Nähe der Air Station ist und eine direkte Sicht ohne Hindernisse '
                '(Wände, Fenster) besteht.',
            'Stelle außerdem sicher, dass deine Air Station mit einem Netzteil mit mindestens '
                '2A Stromstärke verbunden ist.',
          ],
          icon: Icons.bluetooth,
          buttons: [
            FilledButton(
              onPressed: () {
                widget.controller.checkDeviceConnection();
              },
              child: Text('Verbindung erneut versuchen'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.deviceNotVisibleAndBLEButtonNotBlue:
        return buildInfoScreen(
          title: 'Air Station schaltet sich nicht ein',
          body: [
            'Bitte überprüfe die Stromversorgung deiner Air Station. Versuche bespielsweise, '
                'ein anderes Netzteil zu verwenden.',
          ],
          icon: Icons.nearby_error,
          buttons: [
            FilledButton(
              onPressed: () {
                widget.controller.checkDeviceConnection();
              },
              child: Text('LED leuchtet nun blau'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.connectionFailed:
        return buildInfoScreen(
          title: 'Verbindung fehlgeschlagen',
          body: [
            'Wir haben das Signal deiner Air Station gefunden, konnten aber keine Verbindung '
                'aufbauen.',
            'Stelle sicher, dass sich dein Mobilgerät in der Nähe der Air Station befindet und '
                'dass eine Stromversorgung über ein Netzteil mit mindestens 2A Stromstärke '
                'besteht.',
            'Wenn das Problem weiterhin besteht, stelle sicher, dass du die neueste Version dieser '
                'App verwendest.',
            // TODO add link to website instructions on updating firmware
          ],
          icon: Icons.nearby_error,
          buttons: [
            FilledButton(
              onPressed: () {
                widget.controller.checkDeviceConnection();
              },
              child: Text('Verbindung erneut versuchen'.i18n),
            ),
            TextButton(
              onPressed: () {
                AirStationConfigWizardController.removeController(widget.controller.id);
                Navigator.pop(context);
              },
              child: Text('Vorgang beenden'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.failedToLoadConfig:
        return buildInfoScreen(
          title: 'Konfiguration konnte nicht geladen werden',
          body: [
            'Das Auslesen der aktuellen Konfiguration ist fehlgeschlagen. ',
            'Dies liegt wahrscheinlich an einer Inkompatibilität von App und Firmware. '
                'Bitte überprüfe, ob ein Update für diese App verfügbar ist.',
            'Du kannst versuchen, trotzdem mit der Konfiguration fortzufahren, dies kann '
                'jedoch fehlschlagen.',
          ],
          icon: Icons.error_outline,
          buttons: [
            FilledButton(
              onPressed: () {
                AirStationConfigWizardController.removeController(widget.controller.id);
                Navigator.pop(context);
              },
              child: Text('Konfiguration abbrechen'.i18n),
            ),
            TextButton(
              onPressed: () {
                widget.controller.config = AirStationConfig.defaultConfig();
                widget.controller.stage = AirStationConfigWizardStage.editSettings;
              },
              child: Text('Trotzdem fortfahren'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.configureWifiChoice:
        return buildInfoScreen(
          title: 'WLAN-Konfiguration',
          body: [
            'Möchstest du die WLAN-Einstellungen deiner Air Station bearbeiten?',
            'Dies ist beispielsweise notwendig, wenn du das Gerät zum ersten Mal konfigurierst.',
          ],
          icon: Icons.wifi,
          buttons: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    if (widget.controller.wifi == null) {
                      widget.controller.wifi = AirStationWifiConfig();
                      NetworkInfo().getWifiName().then((value) => widget
                          .controller.wifi!.ssidController.text = value?.replaceAll('"', '') ?? '');
                    }
                    widget.controller.stage = AirStationConfigWizardStage.editWifi;
                  },
                  child: Text('Ja'.i18n),
                ),
                const SizedBox(width: 30),
                OutlinedButton(
                  onPressed: () {
                    widget.controller.sendConfiguration();
                  },
                  child: Text('Nein'.i18n),
                ),
              ],
            )
          ],
        );
      case AirStationConfigWizardStage.configTransmissionFailed:
        return buildInfoScreen(
          title: 'Übertragung fehlgeschlagen',
          body: [
            'Wir konnten zwar eine Verbindung mit der Air Station herstellen, bei der '
                'Übertragung der Konfiguration ist jedoch ein Fehler aufgetreten.',
            'Stelle sicher, dass du die aktuellste Version der App verwendest.',
          ],
          icon: Icons.error_outline,
          buttons: [
            FilledButton(
              onPressed: () {
                AirStationConfigWizardController.removeController(widget.controller.id);
                Navigator.pop(context);
              },
              child: Text('Vorgang beenden'.i18n),
            ),
            TextButton(
              onPressed: () {
                widget.controller.sendConfiguration();
              },
              child: Text('Erneut versuchen'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.connectionLostAndNotReestablished:
        return buildInfoScreen(
          title: 'Verbindung verloren',
          body: [
            'Die Verbindung mit der Air Station wurde unterbrochen und konnte nicht '
                'wiederhergestellt werden.',
            'Überprüfe, dass die Air Station in der Nähe ist und dass der Bluetooth-Modus '
                '(blaue LED) eingeschaltet ist. Drücke den „BT“-Knopf, um den Bluetooth-Medus '
                'zu aktivieren.',
          ],
          icon: Icons.bluetooth_disabled_outlined,
          buttons: [
            FilledButton(
              onPressed: () {
                widget.controller.sendConfiguration();
              },
              child: Text('Erneut versuchen'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.checkLed:
        return buildInfoScreen(
          title: 'Übertragung erfolgreich',
          body: [
            'Die Konfiguration wurde übertragen.',
            'Um zu überprüfen, ob die Air Station erfolgreich mit dem WLAN verbunden wurde, '
                'prüfe die Status-LED. Bei erfolgreicher Verbindung leuchtet sie kurz grün, dann '
                'wieder blau. Bei Verbindungsfehlern leuchtet oder blinkt sie rot.',
          ],
          icon: Icons.done,
          buttons: [
            FilledButton(
              onPressed: () {
                widget.controller.waitForFirstData();
              },
              child: Text('LED leuchtet grün/blau'.i18n),
            ),
            OutlinedButton(
              onPressed: () {
                widget.controller.stage = AirStationConfigWizardStage.genericWifiFailure;
              },
              child: Text('LED leuchtet/blinkt rot'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.genericWifiFailure:
        return buildInfoScreen(
          title: 'WLAN-Fehler',
          body: [
            'Eine rote Status-LED deutet auf einen WLAN-Fehler hin. Bitte überprüfe deine Wifi-'
                'Eingaben, insbesondere das Passwort.',
          ],
          icon: Icons.wifi_off,
          buttons: [
            FilledButton(
              onPressed: () {
                widget.controller.wifi ??= AirStationWifiConfig();
                widget.controller.stage = AirStationConfigWizardStage.editWifi;
              },
              child: Text('Zurück zu WLAN-Einstellungen'.i18n),
            ),
            OutlinedButton(
              onPressed: () {
                AirStationConfigWizardController.removeController(widget.controller.id);
                Navigator.pop(context);
              },
              child: Text('Konfiguration beenden'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.firstDataSuccess:
        return buildInfoScreen(
          title: 'Daten erfolgreich empfangen!',
          body: [
            'Deine Air Station sendet erfolgreich Messwerte über WLAN. Du kannst die Mess-'
                'Werte nun im Dashboard verfolgen.',
          ],
          icon: Icons.celebration,
          buttons: [
            FilledButton(
              onPressed: () {
                AirStationConfigWizardController.removeController(widget.controller.id);
                Navigator.pop(context);
              },
              child: Text('Konfiguration abschließen'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.firstDataFailed:
        return buildInfoScreen(
          title: 'Daten wurden nicht gesendet',
          body: [
            'Wir können leider keine Messwerte von deiner Air Station finden.',
            'Leuchtet die Status-LED am Gerät rot? Dann ist ein WLAN-Fehler verantwortlich '
                '(falscher Name oder falsches Passwort).',
            'In anderen Fällen überprüfe, ob andere Geräte in deinem WLAN mit dem Internet '
                'verbunden sind und dass die Air Station eine Stromverbindung besitzt.',
          ],
          icon: Icons.error,
          buttons: [
            FilledButton(
              onPressed: () {
                widget.controller.wifi ??= AirStationWifiConfig();
                widget.controller.stage = AirStationConfigWizardStage.editWifi;
              },
              child: Text('WLAN neu konfigurieren'.i18n),
            ),
            OutlinedButton(
              onPressed: () {
                widget.controller.configSentAt = DateTime.now();
                widget.controller.stage = AirStationConfigWizardStage.waitingForFirstData;
              },
              child: Text('Erneut nach Daten suchen'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.firstDataCheckFailed:
        return buildInfoScreen(
          title: 'Überprüfung fehlgeschlagen',
          body: [
            'Die Suche nach Daten deiner Air Station ist fehlgeschlagen. Dies liegt wahrscheinlich '
                'an fehlernder Internetverbindung deines Mobilgeräts oder an einem internen '
                'Serverproblem auf unserer Seite. Es bedeutet aber nicht, dass deine Air Station '
                'nicht erfolgreich konfiguriert ist.',
            'Du kannst die Konfiguration an dieser Stelle beenden. Die Messwerte deiner Air '
                'Station kannst du im Dashboard einsehen.',
          ],
          icon: Icons.error,
          buttons: [
            FilledButton(
              onPressed: () {
                AirStationConfigWizardController.removeController(widget.controller.id);
                Navigator.pop(context);
              },
              child: Text('Konfiguration beenden'.i18n),
            ),
          ],
        );
      case AirStationConfigWizardStage.editSettings:
        return buildEditConfigScreen();
      case AirStationConfigWizardStage.editWifi:
        return buildEditWifiScreen();
      case AirStationConfigWizardStage.waitingForFirstData:
        return buildWaitForDataScreen();
      case AirStationConfigWizardStage.setLocation:
        return buildSetLocationScreen();
      default:
        return buildLoadingScreen('This should not happen...');
    }
  }

  Widget buildLoadingScreen(String message) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Center(
              child: LottieBuilder.asset('assets/lottie/loading.json',
                  controller: animation, frameRate: FrameRate.max),
            ),
            Text(message.i18n, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget buildInfoScreen(
      {IconData icon = Icons.error_outline,
      required String title,
      required List<String> body,
      required List<Widget> buttons}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Center(
              child: Icon(
                icon,
                size: 90,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(title.i18n, style: const TextStyle(fontSize: 26), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ...body
                .map<Widget>((e) =>
                    Text(e.i18n, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center))
                .toList()
                .spaceWith(const SizedBox(height: 8)),
            const SizedBox(height: 30),
            ...buttons.spaceWith(const SizedBox(), first: const SizedBox(height: 4)),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget buildEditConfigScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Center(
              child: Icon(
                Icons.settings,
                size: 90,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text('Einstellungen'.i18n,
                style: const TextStyle(fontSize: 26), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  'Automatische Updates über WLAN'.i18n,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: DropdownButton(
                    value: widget.controller.config!.autoUpdateMode,
                    isDense: true,
                    items: AutoUpdateMode.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                        .toList(),
                    padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          widget.controller.config!.autoUpdateMode = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(width: 8),
                Expanded(child: Divider(height: 1)),
                SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  'Batteriesparmodus'.i18n,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: DropdownButton(
                    value: widget.controller.config!.batterySaverMode,
                    isDense: true,
                    items: BatterySaverMode.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                        .toList(),
                    padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          widget.controller.config!.batterySaverMode = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(width: 8),
                Expanded(child: Divider(height: 1)),
                SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  'Messintervall'.i18n,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: DropdownButton(
                    value: widget.controller.config!.measurementInterval,
                    isDense: true,
                    items: AirStationMeasurementInterval.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                        .toList(),
                    padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          widget.controller.config!.measurementInterval = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: () {
                widget.controller.stage = AirStationConfigWizardStage.setLocation;
              },
              child: Text('Weiter'.i18n),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget buildSetLocationScreen() {
    // all permission should have benn granted already
    widget.controller.getCurrentLocation();
    double longitude = widget.controller.current_position.longitude;
    double latitude = widget.controller.current_position.latitude;
    double height = widget.controller.config!.height;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Longitude Input Field
            TextFormField(
              initialValue: longitude.toString(), 
              decoration: InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  // Parse input to double and store in config
                  longitude = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 16),

            // Latitude Input Field
            TextFormField(
              initialValue: latitude.toString(),
              decoration: InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  // Parse input to double and store in config
                  latitude = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 16),

            // Height Input Field
            TextFormField(
              initialValue: height.toString(),
              decoration: InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  // Parse input to double and store in config
                  height = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 30),

            // Button to proceed to WiFi Configuration
            ElevatedButton(
              onPressed: () {
                // Set the wizard stage to configureWifiChoice when the button is pressed
                setState(() {
                  widget.controller.config!.longitude = longitude;
                  widget.controller.config!.latitude = latitude;
                  widget.controller.config!.height = height;

                  widget.controller.stage = AirStationConfigWizardStage.configureWifiChoice;
                });
              },
              child: Text('Continue to WiFi Configuration'.i18n),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEditWifiScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Center(
              child: Icon(
                Icons.wifi,
                size: 90,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text('WLAN-Zugangsdaten'.i18n,
                style: const TextStyle(fontSize: 26), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            TextField(
              controller: widget.controller.wifi!.ssidController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'SSID (Netzwerkname)'.i18n,
              ),
              autocorrect: false,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.controller.wifi!.passwordController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Passwort'.i18n,
              ),
              autocorrect: false,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: widget.controller.wifi!.valid
                  ? () {
                      if (widget.controller.wifi!.ssid.endsWith(' ') ||
                          widget.controller.wifi!.password.endsWith(' ')) {
                        showLDDialog(
                          context,
                          title: 'Leerzeichen'.i18n,
                          icon: Icons.format_quote,
                          text: 'Der WLAN-Name oder das WLAN-Passwort enden mit Leerzeichen. '
                                  'Möchtest du diese bearbeiten?'
                              .i18n,
                          actions: [
                            LDDialogAction(
                              label: 'Behalten'.i18n,
                              filled: false,
                              onTap: () {
                                widget.controller.stage =
                                    AirStationConfigWizardStage.configureWifiChoice;
                              },
                            ),
                            LDDialogAction(
                              label: 'Bearbeiten'.i18n,
                              filled: true,
                            ),
                          ],
                        );
                      } else {
                        widget.controller.sendConfiguration();
                      }
                    }
                  : null,
              child: Text('Konfiguration senden'.i18n),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                widget.controller.stage = AirStationConfigWizardStage.editSettings;
                widget.controller.wifi = null;
              },
              child: Text('Zurück'.i18n),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget buildWaitForDataScreen() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Warte auf erste Daten'.i18n,
                    style: const TextStyle(fontSize: 26), textAlign: TextAlign.center),
                const Ellipsis(style: TextStyle(fontSize: 26), fixedWidth: true),
              ],
            ),
            const SizedBox(height: 5),
            Center(
              child: LottieBuilder.asset(
                'assets/lottie/loading.json',
                controller: animation,
                frameRate: FrameRate.max,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Du kannst den Bluetooth-Modus an der Air Station nun durch drücken des BT-Buttons '
              'ausschalten. Die Status-LED sollte erlischen.'
                  .i18n,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Während wir auf die ersten Daten deiner Air Station warten, kannst du bereits '
                      'andere Teile der App erkunden. Den Status deiner Air Station kannst du im '
                      'Dashboard einsehen.'
                  .i18n,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                getIt<PageController>().jumpToPage(0);
              },
              child: Text('Zum Dashboard'.i18n),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  bool canPop() {
    if (widget.controller.stage == AirStationConfigWizardStage.waitingForFirstData) {
      return true;
    }
    if (widget.controller.stage == AirStationConfigWizardStage.firstDataSuccess) {
      return true;
    }
    return false;
  }

  void onPop() {
    if (widget.controller.stage == AirStationConfigWizardStage.waitingForFirstData) {
      // Do nothing here, we're just waiting for data
    } else if (widget.controller.stage == AirStationConfigWizardStage.firstDataSuccess) {
      // Natural end point, destroy wizard
      // Pop would already have proceeded
      AirStationConfigWizardController.removeController(widget.controller.id);
    } else {
      // Ask for user to confirm where they wish to return to the wizard
      showLDDialog(
        context,
        title: 'Konfigurator verlassen'.i18n,
        icon: Icons.settings,
        text: 'Möchtest du die Konfiguration später fortsetzen oder den Konfigurator '
                'vollständig beenden?'
            .i18n,
        actions: [
          LDDialogAction(
            label: 'Beenden'.i18n,
            filled: false,
            onTap: () async {
              await Future.delayed(Duration.zero);
              if(!mounted) return;
              Navigator.of(context).pop();
              AirStationConfigWizardController.removeController(widget.controller.id);
            },
          ),
          LDDialogAction(
            label: 'Später fortsetzen'.i18n,
            filled: true,
            onTap: () async {
              await Future.delayed(Duration.zero);
              if(!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    }
  }
}
