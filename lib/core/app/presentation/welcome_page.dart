import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:luftdaten.at/core/app/presentation/welcome_page.i18n.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:luftdaten.at/core/widgets/ui.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  static const String route = 'welcome';

  @override
  State<StatefulWidget> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool airStation = false, airARound = false, noDevices = false;
  _PageState state = _PageState.options;
  Map<_Permission, bool> statuses = {
    _Permission.nearbyDevices: false,
    _Permission.locationWhileInUse: false,
    _Permission.locationAlways: false,
    _Permission.disableBatteryOptimization: false,
    _Permission.camera: false,
    _Permission.notifications: false,
  };
  List<ExpansionTileController> controllers = [
    ExpansionTileController(),
    ExpansionTileController(),
    ExpansionTileController(),
    ExpansionTileController(),
    ExpansionTileController(),
  ];
  List<bool> isLoading = List.filled(5, false);

  @override
  void initState() {
    checkAllPermissions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Willkommen'.i18n, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (state) {
      case _PageState.permissions:
        return _buildPermissionsScreenContent();
      case _PageState.options:
        return _buildWelcomeScreenContent();
    }
  }

  Widget _buildPermissionsScreenContent() {
    List<_Device> devices = [
      if (airARound) _Device.aRound,
      if (airStation) _Device.station,
      _Device.generalUse
    ];
    _Platform platform = Platform.isIOS ? _Platform.iOS : _Platform.android;
    List<_Permission> required = getRequiredPermissions(devices, platform);
    List<_Permission> recommended = getRecommendedPermissions(devices, platform);
    List<_Permission> other = getOtherPermissions(devices, platform);
    return SizedBox(
      key: const Key('welcome-permissions'),
      height: double.infinity,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        state = _PageState.options;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chevron_left),
                        Text('Zurück'.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              if (required.isNotEmpty)
                Text(
                  'Benötigte Berechtigungen:'.i18n,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (required.isNotEmpty) const SizedBox(height: 5),
              ...required.asMap().entries.map((e) => _permissionRow(e.value, e.key)),
              if (required.isNotEmpty) const SizedBox(height: 15),
              if (recommended.isNotEmpty)
                Text(
                  'Empfohlene Berechtigungen:'.i18n,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (recommended.isNotEmpty) const SizedBox(height: 5),
              ...recommended
                  .asMap()
                  .entries
                  .map((e) => _permissionRow(e.value, e.key + required.length)),
              if (recommended.isNotEmpty) const SizedBox(height: 15),
              if (other.isNotEmpty)
                Text(
                  'Andere Berechtigungen:'.i18n,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (other.isNotEmpty) const SizedBox(height: 5),
              ...other.asMap().entries.map(
                  (e) => _permissionRow(e.value, e.key + recommended.length + required.length)),
              if (other.isNotEmpty) const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      bool requiredPermissionsGranted = true;
                      for (var e in required) {
                        if (!statuses[e]!) {
                          requiredPermissionsGranted = false;
                        }
                      }
                      bool recommendedPermissionsGranted = true;
                      for (var e in recommended) {
                        if (!statuses[e]!) {
                          recommendedPermissionsGranted = false;
                        }
                      }
                      if (!requiredPermissionsGranted || !recommendedPermissionsGranted) {
                        showLDDialog(
                          context,
                          content: Text(
                            '${'Ohne'.i18n} ${requiredPermissionsGranted ? 'empfohlene'.i18n : 'benötigte'.i18n} ${'Berechtigungen fortfahren? Fehlende Berechtigungen können zu unerwartetem Verhalten der App und etwaigen Messgeräten führen.'.i18n}',
                            textAlign: TextAlign.center,
                          ),
                          title: 'Fortfahren?'.i18n,
                          icon: Icons.info,
                          actions: [
                            LDDialogAction(
                              label: 'Weiter'.i18n,
                              filled: false,
                              onTap: () =>
                                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                            ),
                            LDDialogAction(label: 'Zurück'.i18n, filled: true),
                          ],
                        );
                      } else {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Weiter'.i18n,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreenContent() {
    return SizedBox(
      key: const Key('welcome-options'),
      height: double.infinity,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(flex: 1),
                  SvgPicture.asset(
                    'assets/LD_logo_wordmark_blue.svg',
                    height: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                  const Spacer(flex: 1),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Um deine Luftdaten.at-Messgeräte zu verwenden, sind bestimmte Berechtigungen notwendig.'
                    .i18n,
              ),
              const SizedBox(height: 5),
              Text('Für welche der folgenden Geräte möchtest du die App verwenden?'.i18n),
              const SizedBox(height: 5),
              Row(
                children: [
                  Checkbox(
                    value: airARound,
                    onChanged: (val) {
                      setState(() {
                        if (val != null) {
                          airARound = val;
                        }
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    'Air aRound (tragbares Messgerät)'.i18n,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: airStation,
                    onChanged: (val) {
                      setState(() {
                        if (val != null) {
                          airStation = val;
                        }
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    'Air Station (stationäres Messgerät)'.i18n,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: noDevices,
                    onChanged: (val) {
                      setState(() {
                        if (val != null) {
                          noDevices = val;
                        }
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    'Keine'.i18n,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        state = _PageState.permissions;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Weiter'.i18n,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionRow(_Permission permission, int index) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ListTileTheme(
        contentPadding: const EdgeInsets.all(0),
        minLeadingWidth: 0,
        horizontalTitleGap: 0,
        dense: true,
        child: ExpansionTile(
          controller: controllers[index],
          initiallyExpanded: index == 0,
          title: Row(
            children: [
              statusIcon(statuses[permission]!),
              const SizedBox(width: 5),
              Text(
                permission.name.i18n,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statuses[permission]! ? Colors.grey : null,
                ),
              ),
            ],
          ),
          tilePadding: const EdgeInsets.only(right: 20),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(permission.desc.i18n),
                if (permission.reasoning.where((e) => isPermissionRequired(permission)).isNotEmpty)
                  const SizedBox(height: 5),
                if (permission.reasoning.where((e) => isPermissionRequired(permission)).isNotEmpty)
                  Text('Benötigt für:'.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
                ...permission.reasoning
                    .where((e) => isPermissionRequired(permission) && showDevice(e.device))
                    .map((e) => e.toText(context)),
                if (permission.reasoning.where((e) => !isPermissionRequired(permission)).isNotEmpty)
                  const SizedBox(height: 5),
                if (permission.reasoning
                    .where((e) => !isPermissionRequired(permission) && showDevice(e.device))
                    .isNotEmpty)
                  Text('Empfohlen für:'.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
                ...permission.reasoning
                    .where((e) => !isPermissionRequired(permission) && showDevice(e.device))
                    .map((e) => e.toText(context)),
                Row(
                  children: [
                    const Spacer(flex: 1),
                    _requestButton(
                      granted: statuses[permission]!,
                      loading: isLoading[index],
                      onPressed: () async {
                        setState(() {
                          isLoading[index] = true;
                        });
                        bool wasGranted = await requestPermission(permission);
                        if (wasGranted) {
                          controllers[index].collapse();
                          if (index + 1 < controllers.length) {
                            controllers[index + 1].expand();
                          }
                        }
                        checkAllPermissions();
                        setState(() {
                          isLoading[index] = false;
                        });
                        Future.delayed(const Duration(seconds: 1))
                            .then((_) => checkAllPermissions());
                      },
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestButton({
    bool granted = false,
    bool loading = false,
    required void Function() onPressed,
  }) {
    Widget label;
    if (granted) {
      label = Icon(Icons.check, size: 18, color: Colors.green.shade900);
    } else if (loading) {
      label = SpinKitDualRing(
        size: 18,
        color: Colors.green.shade900,
        lineWidth: 2,
        duration: const Duration(milliseconds: 800),
      );
    } else {
      label = Text(
        'Anfragen'.i18n,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      );
    }
    return TextButton(
      onPressed: !granted && !loading ? onPressed : null,
      style: ButtonStyle(
        backgroundColor:
            MaterialStateProperty.all((granted || loading) ? Colors.green.shade100 : Colors.green),
      ),
      child: SizedBox(
        width: 70,
        child: Center(
          child: label,
        ),
      ),
    );
  }

  Future<bool> requestPermission(_Permission permission) async {
    switch (permission) {
      case _Permission.nearbyDevices:
        if (Platform.isIOS) {
          return (await Permission.bluetooth.request()).isGranted;
        } else {
          await Permission.location.request();
          return (await Permission.bluetoothConnect.request()).isGranted;
        }
      case _Permission.locationWhileInUse:
        return (await Permission.locationWhenInUse.request()).isGranted;
      case _Permission.locationAlways:
        return (await Permission.locationAlways.request()).isGranted;
      case _Permission.disableBatteryOptimization:
        return (await Permission.ignoreBatteryOptimizations.request()).isGranted;
      case _Permission.camera:
        return (await Permission.camera.request()).isGranted;
      case _Permission.notifications:
        return (await Permission.notification.request()).isGranted;
    }
  }

  bool showDevice(_Device dev) {
    return [if (airARound) _Device.aRound, if (airStation) _Device.station, _Device.generalUse]
        .contains(dev);
  }

  bool isPermissionRequired(_Permission permission) {
    List<_Device> devs = [
      if (airARound) _Device.aRound,
      if (airStation) _Device.station,
      _Device.generalUse
    ];
    return permission.reasoning.where((e) => (devs.contains(e.device) && e.required)).isNotEmpty;
  }

  Widget statusIcon(bool status) {
    return Icon(
      status ? Icons.check : Icons.close,
      color: status ? Colors.green : Colors.red,
      size: 20,
    );
  }

  List<_Permission> getRequiredPermissions(List<_Device> devices, _Platform platform) {
    List<_Permission> permissions = [];
    for (_Permission permission in _Permission.values) {
      bool add = false;
      for (_Device device in devices) {
        if (permission.reasoning.where((e) => ((e.device == device) && e.required)).isNotEmpty) {
          if (permission.platforms.contains(platform)) {
            add = true;
          }
        }
      }
      if (add) {
        permissions.add(permission);
      }
    }
    return permissions;
  }

  void checkAllPermissions() async {
    statuses = {
      _Permission.nearbyDevices: await hasPermission(_Permission.nearbyDevices),
      _Permission.locationWhileInUse: await hasPermission(_Permission.locationWhileInUse),
      _Permission.locationAlways: await hasPermission(_Permission.locationAlways),
      _Permission.disableBatteryOptimization:
          await hasPermission(_Permission.disableBatteryOptimization),
      _Permission.camera: await hasPermission(_Permission.camera),
      _Permission.notifications: await hasPermission(_Permission.notifications),
    };
    setState(() {});
  }

  Future<bool> hasPermission(_Permission permission) async {
    try {
      switch (permission) {
        case _Permission.nearbyDevices:
          return await Permission.bluetoothConnect.isGranted;
        case _Permission.locationWhileInUse:
          return await Permission.locationWhenInUse.isGranted;
        case _Permission.locationAlways:
          return await Permission.locationAlways.isGranted;
        case _Permission.disableBatteryOptimization:
          return await Permission.ignoreBatteryOptimizations.isGranted;
        case _Permission.camera:
          return await Permission.camera.isGranted;
        case _Permission.notifications:
          return await Permission.notification.isGranted;
      }
    } catch(_) {
      return false;
    }
  }

  List<_Permission> getRecommendedPermissions(List<_Device> devices, _Platform platform) {
    List<_Permission> permissions = [];
    for (_Permission permission in _Permission.values) {
      bool add = false;
      for (_Device device in devices) {
        if (permission.reasoning.where((e) => ((e.device == device) && !e.required)).isNotEmpty) {
          if (permission.platforms.contains(platform)) {
            add = true;
          }
        }
      }
      // Remove any permissions that are already listed as required
      // (e.g. because they are required for one device and options for another)
      for (_Device device in devices) {
        if (permission.reasoning.where((e) => ((e.device == device) && e.required)).isNotEmpty) {
          add = false;
        }
      }
      if (add) {
        permissions.add(permission);
      }
    }
    return permissions;
  }

  List<_Permission> getOtherPermissions(List<_Device> devices, _Platform platform) {
    List<_Permission> permissions = [];
    for (_Permission permission in _Permission.values) {
      bool dontAdd = false;
      for (_Device device in devices) {
        if (permission.reasoning.where((e) => (e.device == device)).isNotEmpty) {
          dontAdd = true;
        }
      }
      if (!permission.platforms.contains(platform)) {
        dontAdd = true;
      }
      if (!dontAdd) {
        permissions.add(permission);
      }
    }
    return permissions;
  }
}

enum _PageState { options, permissions }

enum _Platform { iOS, android }

enum _Permission {
  nearbyDevices(
    name: 'Bluetooth (Geräte in der Nähe)',
    desc: 'Erlaubt es der App, sich mit Bluetooth Low Energy (BLE) Geräten '
        'in der Nähe zu verbinden.',
    reasoning: [
      _ReasoningItem(
        device: _Device.aRound,
        reasoning: 'Steuerung der Messung und Auslesen der Messdaten',
        required: true,
      ),
      _ReasoningItem(
        device: _Device.station,
        reasoning: 'Einrichten des Geräts',
        required: true,
      ),
    ],
    platforms: [_Platform.iOS, _Platform.android],
  ),
  locationWhileInUse(
    name: 'Standortermittlung',
    desc: 'Erlaubt es der App, deinen Standort zu ermitteln, während die App geöffnet ist.',
    reasoning: [
      _ReasoningItem(
        device: _Device.aRound,
        reasoning: 'Verbinden von Messdaten mit Standorten',
      ),
      _ReasoningItem(
        device: _Device.generalUse,
        reasoning: 'Anzeigen deines Standorts auf der Luftkarte',
      ),
    ],
    platforms: [_Platform.iOS, _Platform.android],
  ),
  locationAlways(
    name: 'Standortermittlung im Hintergrund',
    desc: 'Erlaubt es der App, deinen Standort auch dann zu ermitteln, wenn die App nicht '
        'geöffnet ist (z. B., wenn du während einer Messung deinen Handybildschirm ausschaltest.',
    reasoning: [
      _ReasoningItem(
        device: _Device.aRound,
        reasoning: 'Verbinden von Messdaten mit Standorten, während Bildschirm ausgeschaltet ist',
      ),
    ],
    platforms: [_Platform.iOS],
  ),
  disableBatteryOptimization(
    name: 'Akku-Optimierung deaktivieren',
    desc: 'Nimmt die App von Androids Akku-Optimisierung aus. Akku-Optimisierung kann dazu führen, '
        'dass Messvorgänge unerwartet abgebrochen werden, weil das System die App während der '
        'Messung schließt.',
    reasoning: [
      _ReasoningItem(
        device: _Device.aRound,
        reasoning: 'Stabilen Messvorgang',
      ),
    ],
    platforms: [_Platform.android],
  ),
  camera(
    name: 'Kamera',
    desc: 'Ermöglicht es der App, einen QR-Code-Scanner für das schnellere Verbinden '
        'mit Geräten anzubieten.',
    reasoning: [
      _ReasoningItem(
        device: _Device.aRound,
        reasoning: 'Verbindung zum Gerät mittels QR-Code',
      ),
      _ReasoningItem(
        device: _Device.station,
        reasoning: 'Verbindung zum Gerät mittels QR-Code',
      ),
    ],
    platforms: [_Platform.iOS, _Platform.android],
  ),
  notifications(
    name: 'Benachrichtigungen',
    desc: 'Erlaubt es der App, Benachrichtigungen zu senden.',
    reasoning: [
      _ReasoningItem(
        device: _Device.aRound,
        reasoning: 'Meldung von Regionen erhöhter Luftverschmutzung',
      ),
      _ReasoningItem(
        device: _Device.station,
        reasoning: 'Meldung von Zeiten erhöhter Luftverschmutzung',
      ),
      _ReasoningItem(
        device: _Device.generalUse,
        reasoning: 'Statusmeldungen über die lokale Luftqualität',
      ),
    ],
    platforms: [_Platform.iOS, _Platform.android],
  );

  const _Permission(
      {required this.name, required this.desc, required this.reasoning, required this.platforms});

  final String name, desc;
  final List<_ReasoningItem> reasoning;
  final List<_Platform> platforms;
}

enum _Device {
  aRound(title: 'Air aRound'),
  station(title: 'Air Station'),
  generalUse(title: 'Generelle Nutzung');

  const _Device({required this.title});

  final String title;
}

class _ReasoningItem {
  const _ReasoningItem({required this.device, required this.reasoning, this.required = false});

  final _Device device;
  final String reasoning;
  final bool required;

  Widget toText(BuildContext context) {
    return RichText(
        text: TextSpan(
      style: Theme.of(context).textTheme.bodyMedium!,
      children: [
        TextSpan(text: '${device.title}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: reasoning.i18n),
      ],
    ));
  }
}
