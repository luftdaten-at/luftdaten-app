import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:i18n_extension/default.i18n.dart';
import 'package:luftdaten.at/controller/workshop_controller.dart';
import 'package:luftdaten.at/model/app_permissions.dart';
import 'package:luftdaten.at/page/device_manager_page.dart';
import 'package:luftdaten.at/page/enter_workshop_page.dart';

import '../main.dart';

class WelcomeWizardPage extends StatefulWidget {
  const WelcomeWizardPage({super.key});

  @override
  State<WelcomeWizardPage> createState() => _WelcomeWizardPageState();
}

class _WelcomeWizardPageState extends State<WelcomeWizardPage> {
  _State _state = _State.landing;
  int _currentPermission = -1;
  List<AppPermission> _permissions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff2e88c1),
        title: Text('Willkommen'.i18n, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _State.landing:
        return _buildLanding();
      case _State.ldDeviceSelection:
        return _buildLdDeviceSelection();
      case _State.permission:
        return _buildPermission();
      case _State.workshopQuestion:
        return _buildWorkshop();
      case _State.addDeviceQuestion:
        return _buildAddDeviceQuestion();
    }
  }

  bool ak = false;

  Widget _buildLanding() {
    return SingleChildScrollView(
      key: const Key('welcome-wizard-landing'),
      child: Column(
        children: [
          const SizedBox(height: 60),
          SvgPicture.asset(
            'assets/LD_logo_wordmark_blue.svg',
            height: 40,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Für welchen Zweck möchtest Du die Luftdaten.at-App verwenden? Du kannst die App später auch für weitere Zwecke konfigurieren.'
                  .i18n,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _WelcomeWizardTile(
            text: 'Ich möchte die Luftqualität in meiner Umgebung auf unserer Luftkarte einsehen.'
                .i18n,
            backgroundColor: Colors.green.shade50,
            borderColor: Colors.green.shade400,
            onTap: () {
              Navigator.of(context).pushNamed('/');
            },
          ),
          _WelcomeWizardTile(
            text:
                'Ich möchte mit einem Luftdaten.at-Messgerät (Air aRound, Air Station) messen, alleine oder als Teil einer Messkampagne.'
                    .i18n,
            backgroundColor: Colors.blue.shade50,
            borderColor: Colors.blue.shade400,
            onTap: () {
              ak = false;
              setState(() => _state = _State.ldDeviceSelection);
            },
          ),
          _WelcomeWizardTile(
            text: 'Ich möchte am Projekt „Luftqualität am Arbeitsplatz“ (AK Wien) teilnehmen.'.i18n,
            backgroundColor: Colors.red.shade50,
            borderColor: Colors.red.shade400,
            onTap: () async {
              ak = true;
              //Navigator.of(context).pushNamed('wizard-air-cube');
              _currentPermission = 0;
              _permissions = [];
              List<AppPermission> permissions = [
                AppPermissions.nearbyDevices,
                AppPermissions.locationWhileInUse,
                if (AppPermissions.locationAlways.appliesToPlatform) AppPermissions.locationAlways,
                if (AppPermissions.disableBatteryOptimization.appliesToPlatform)
                  AppPermissions.disableBatteryOptimization,
                AppPermissions.camera,
                AppPermissions.notifications,
              ];
              logger.d('About to check permissions');
              for (AppPermission permission in permissions) {
                if (!(await permission.granted)) {
                  _permissions.add(permission);
                }
              }
              if (_permissions.isNotEmpty) {
                logger.d('Navigating to permission requests');
                setState(() => _state = _State.permission);
              } else {
                logger.d('Navigating to workshop question');
                setState(() => _state = _State.workshopQuestion);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLdDeviceSelection() {
    return SingleChildScrollView(
      key: const Key('welcome-wizard-ld-device'),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Welches Gerätemodell möchtest du verwenden?'.i18n,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _WelcomeWizardTile(
            text: 'Tragbares Messgerät (z. B. Air aRound)'.i18n,
            asset: 'assets/images/air_around_v1.png',
            backgroundColor: Colors.blue.shade50,
            borderColor: Colors.blue.shade400,
            onTap: () async {
              _currentPermission = 0;
              _permissions = [];
              List<AppPermission> permissions = [
                AppPermissions.nearbyDevices,
                AppPermissions.locationWhileInUse,
                if (AppPermissions.locationAlways.appliesToPlatform) AppPermissions.locationAlways,
                if (AppPermissions.disableBatteryOptimization.appliesToPlatform)
                  AppPermissions.disableBatteryOptimization,
                AppPermissions.camera,
                AppPermissions.notifications,
              ];
              logger.d('About to check permissions');
              for (AppPermission permission in permissions) {
                if (!(await permission.granted)) {
                  _permissions.add(permission);
                }
              }
              if (_permissions.isNotEmpty) {
                logger.d('Navigating to permission requests');
                setState(() => _state = _State.permission);
              } else {
                logger.d('Navigating to workshop question');
                setState(() => _state = _State.workshopQuestion);
              }
            },
          ),
          _WelcomeWizardTile(
            text: 'Stationäres Messgerät (z. B. Air Station)'.i18n,
            asset: 'assets/images/air_station_v3.png',
            backgroundColor: Colors.blue.shade50,
            borderColor: Colors.blue.shade400,
            onTap: () {},
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _state = _State.landing),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left),
                    Text('Zurück'.i18n),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermission() {
    AppPermission permission = _permissions[_currentPermission];
    String name;
    String description;
    bool required;
    IconData icon;
    if (permission == AppPermissions.camera) {
      name = 'Kamera'.i18n;
      description = 'Die Kamera wird benötigt, um den QR-Code des Messgeräts zu scannen.'.i18n;
      required = false;
      icon = Icons.camera_alt;
    } else if (permission == AppPermissions.nearbyDevices) {
      name = 'Bluetooth'.i18n;
      description = 'Bluetooth wird benötigt, um mit dem Messgerät zu kommunizieren.'.i18n;
      required = true;
      icon = Icons.bluetooth;
    } else if (permission == AppPermissions.locationWhileInUse) {
      name = 'Standort'.i18n;
      description = 'Der Standort wird benötigt, um die Messwerte auf der Karte anzuzeigen.'.i18n;
      required = false;
      icon = Icons.location_on;
    } else if (permission == AppPermissions.locationAlways) {
      name = 'Standort im Hintergrund'.i18n;
      description =
          'Die Berechtigung „Standortermittlung im Hintergrund“ wird benötigt, um auch im Hintergrund gemessene Messwerte auf der Karte anzuzeigen.'
              .i18n;
      required = false;
      icon = Icons.location_on;
    } else if (permission == AppPermissions.disableBatteryOptimization) {
      name = 'Akkuoptimierung'.i18n;
      description =
          'Die Akkuoptimierung wird deaktiviert, um die Messwerte auch im Hintergrund zu aktualisieren.'
              .i18n;
      required = false;
      icon = Icons.battery_full;
    } else if (permission == AppPermissions.notifications) {
      name = 'Benachrichtigungen'.i18n;
      description =
          'Benachrichtigungen werden benötigt, um über wichtige Ereignisse informiert zu werden.'
              .i18n;
      required = false;
      icon = Icons.notifications;
    } else {
      name = 'Unbekannt'.i18n;
      description = 'Unbekannte Berechtigung'.i18n;
      required = false;
      icon = Icons.error;
    }

    return SingleChildScrollView(
      key: Key('welcome-wizard-permission-$_currentPermission'),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Benötigte Berechtigungen'.i18n,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_currentPermission + 1}/${_permissions.length}'.i18n,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(description),
                  ]),
                ),
                const SizedBox(width: 20),
                Icon(
                  icon,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(required
                      ? 'Diese Berechtigung ist für die Funktion der App notwendig.'.i18n
                      : 'Diese Berechtigung ist optional, aber für die optimale Funktion der App empfohlen. Du kannst sie auch später in den Einstellungen der App aktivieren.'
                          .i18n),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  if (_currentPermission > 0) {
                    setState(() => _currentPermission--);
                  } else {
                    setState(() => _state = _State.ldDeviceSelection);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left),
                    Text('Zurück'.i18n),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await permission.request();
                  if (_currentPermission < _permissions.length - 1) {
                    setState(() => _currentPermission++);
                  } else {
                    setState(() => _state = _State.workshopQuestion);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Anfragen'.i18n),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkshop() {
    return SingleChildScrollView(
      key: const Key('welcome-wizard-ld-workshop'),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              ak ? 'Messkampagne beitreten' : 'Möchstest du an einer Luftdaten.at-Messkampagne teilnehmen?'.i18n,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _WelcomeWizardTile(
            text: ak ? 'Beitritts-Code eingeben' : 'Ja, ich habe einen Teilnahmecode'.i18n,
            backgroundColor: Colors.green.shade50,
            borderColor: Colors.green.shade400,
            onTap: () async {
              if (getIt<WorkshopController>().currentWorkshop == null) {
                Navigator.of(context).pushNamed(ak ? 'ak-ws' : EnterWorkshopPage.route).then((e) {
                  if (e == true) {
                    setState(() => _state = _State.addDeviceQuestion);
                  }
                });
              } else {
                setState(() => _state = _State.addDeviceQuestion);
              }
            },
          ),
          if(!ak)
          _WelcomeWizardTile(
            text: 'Nein, ich möchte alleine messen'.i18n,
            backgroundColor: Colors.red.shade50,
            borderColor: Colors.red.shade400,
            onTap: () {
              setState(() => _state = _State.addDeviceQuestion);
            },
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() {
                  if(_permissions.isNotEmpty) {
                    _state = _State.permission;
                  } else {
                    _state = _State.ldDeviceSelection;
                  }
                }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left),
                    Text('Zurück'.i18n),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddDeviceQuestion() {
    return SingleChildScrollView(
      key: const Key('welcome-wizard-add-device-q'),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Hast du ein Gerät bei der Hand, mit dem du dich verbinden möchtest?'.i18n,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _WelcomeWizardTile(
            text: 'Ja, Gerät einscannen'.i18n,
            backgroundColor: Colors.green.shade50,
            borderColor: Colors.green.shade400,
            onTap: () async {
              Navigator.of(context).pushNamed(QRCodePage.route).then((e) {
                if (e != null) {
                  Navigator.of(context).pushNamed('/');
                }
              });
            },
          ),
          _WelcomeWizardTile(
            text: 'Nein, später verbinden'.i18n,
            backgroundColor: Colors.red.shade50,
            borderColor: Colors.red.shade400,
            onTap: () {
              Navigator.of(context).pushNamed('/');
            },
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _state = _State.workshopQuestion),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left),
                    Text('Zurück'.i18n),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _State { landing, ldDeviceSelection, permission, workshopQuestion, addDeviceQuestion }

class _WelcomeWizardTile extends StatelessWidget {
  const _WelcomeWizardTile(
      {super.key,
      required this.text,
      this.asset,
      required this.backgroundColor,
      required this.borderColor,
      required this.onTap});

  final String text;
  final String? asset;
  final Color backgroundColor;
  final Color borderColor;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 3),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Row(
                  children: [
                    if (asset != null)
                      SizedBox(width: 80, child: Center(child: Image.asset(asset!))),
                    Expanded(
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
