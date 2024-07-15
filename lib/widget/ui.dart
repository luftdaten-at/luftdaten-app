/*  
   Copyright (C) 2023 Thomas Ogrisegg for luftdaten.at
      
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
   GNU General Public License for more details.
  
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
  
 */

import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/widget/device_connect_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../model/ble_device.dart';
import '../page/device_manager_page.dart';
import 'change_notifier_builder.dart';
import 'ui.i18n.dart';

void snackMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

Widget getBLEStatus(BleDevice dev) {
  return Container(
    margin: const EdgeInsets.only(left: 24.0),
    decoration: BoxDecoration(
      color: devStateColors[dev.state] ?? Colors.red,
      border: Border.all(
        color: devStateColors[dev.state] ?? Colors.red,
      ),
      borderRadius: const BorderRadius.all(
        Radius.circular(20),
      ),
    ),
    height: 12,
    width: 12,
  );
}

Future<BleDevice?> showDeviceSelectDialog(BuildContext context, Function stopCB,
    {bool portable = true}) async {
  BleDevice? device;
  // Check bluetooth (permissions & availability) and location (permissions only)
  // Check bluetooth
  if (FlutterReactiveBle().status == BleStatus.unauthorized) {
    if (!(await Permission.bluetoothScan.isPermanentlyDenied)) {
      PermissionStatus status = await Permission.bluetoothScan.request();
      if (status != PermissionStatus.granted) {
        if (context.mounted) {
          await showLDDialog(
            context,
            content: Text(
              'Zum Datenempfang ist die Berechtigung, Bluetooth zu verwenden, um Geräte in der '
                      'Nähe zu finden, notwendig.'
                  .i18n,
              textAlign: TextAlign.center,
            ),
            actions: [
              LDDialogAction(
                label: 'OK'.i18n,
                filled: false,
              ),
              LDDialogAction(
                label: 'Einstellungen öffnen'.i18n,
                filled: true,
                onTap: openAppSettings,
              ),
            ],
            title: 'Geräte in der Nähe'.i18n,
            icon: Icons.nearby_error,
          );
        }
        return null;
      }
    } else {
      if (context.mounted) {
        await showLDDialog(
          context,
          content: Text(
            'Zum Datenempfang ist die Berechtigung, Bluetooth zu verwenden, um Geräte in der '
                    'Nähe zu finden, notwendig.'
                .i18n,
            textAlign: TextAlign.center,
          ),
          actions: [
            LDDialogAction(
              label: 'OK'.i18n,
              filled: false,
            ),
            LDDialogAction(
              label: 'Einstellungen öffnen'.i18n,
              filled: true,
              onTap: openAppSettings,
            ),
          ],
          title: 'Geräte in der Nähe'.i18n,
          icon: Icons.nearby_error,
        );
      }
      return null;
    }
  }
  // Check when-in-use location
  if (!(await Permission.location.isGranted) && false) {
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.locationWhenInUse.request();
    } else {
      status = await Permission.locationAlways.request();
    }
    logger.d('Permission status is $status');
    if (status != PermissionStatus.granted) {
      if (context.mounted) {
        await showLDDialog(
          context,
          content: Text(
            'Damit Messdaten mit Standorten verbunden werden können, ist die Standort-Ermitterungs-'
                    'Berechtigung empfohlen.'
                .i18n,
            textAlign: TextAlign.center,
          ),
          title: 'Standortberechtigung'.i18n,
          actions: [
            LDDialogAction(
              label: 'OK'.i18n,
              filled: false,
            ),
            LDDialogAction(
              label: 'Einstellungen öffnen'.i18n,
              filled: true,
              onTap: openAppSettings,
            ),
          ],
          icon: Icons.map,
        );
      }
    }
  }
  // Check always-on location (iOS only, Android foreground services count as when-in-use)
  if ((!(await Permission.locationAlways.isGranted)) && Platform.isIOS && false) {
    PermissionStatus status = await Permission.locationAlways.request();
    if (status != PermissionStatus.granted) {
      if (context.mounted) {
        await showLDDialog(
          context,
          content: Text(
            'Damit Messdaten auch im Hintergrund aufgezeichnet werden können, ist die '
                    'Berechtigung "Standortermittlung im Hintergrund" empfohlen.'
                .i18n,
            textAlign: TextAlign.center,
          ),
          title: 'Standortberechtigung'.i18n,
          actions: [
            LDDialogAction(
              label: 'OK'.i18n,
              filled: false,
            ),
            LDDialogAction(
              label: 'Einstellungen öffnen'.i18n,
              filled: true,
              onTap: openAppSettings,
            ),
          ],
          icon: Icons.map,
        );
      }
    }
  }
  // Check that bluetooth is on
  if (FlutterReactiveBle().status != BleStatus.ready) {
    // Request to turn on Bluetooth within an app
    String enableResult = await BluetoothEnable.enableBluetooth;
    if (enableResult == "false") {
      if (context.mounted) {
        await showLDDialog(
          context,
          title: 'Bluetooth benötigt'.i18n,
          content: Text(
            'Bluetooth muss eingeschaltet sein, um Verbindung zu Messgeräten herzustellen.'.i18n,
            textAlign: TextAlign.center,
          ),
          icon: Icons.bluetooth,
          actions: [
            LDDialogAction(
              label: 'OK'.i18n,
              filled: false,
            ),
            LDDialogAction(
              label: 'Einstellungen öffnen'.i18n,
              filled: true,
              onTap: () => AppSettings.openAppSettings(type: AppSettingsType.bluetooth),
            ),
          ],
        );
      }
      return null;
    }
  }

  List<BleDevice> devices = getIt<DeviceManager>().devices;
  List<BleDevice> connectedDevices =
      devices.where((e) => e.state == BleDeviceState.connected).toList();
  if (connectedDevices.length == 1) {
    device = connectedDevices.first;
  } else {
    //getIt<DeviceManager>().scanForDevices(1000);
    if (context.mounted) {
      await showLDDialog(
        context,
        title: "Gerät auswählen".i18n,
        icon: Icons.bluetooth_connected,
        content: SingleChildScrollView(
          child: Consumer<DeviceManager>(
            builder: (context, devs, __) {
              Future.delayed(const Duration(milliseconds: 100))
                  .then((_) => devs.scanForDevices(1000));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (var cd in devs.devices.where((e) => e.portable))
                    ChangeNotifierBuilder(
                      notifier: cd,
                      builder: (context, cd) {
                        return ListTile(
                          title: Text(cd.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          //leading: getBLEStatus(cd),
                          trailing: DeviceConnectButton(
                            device: cd,
                            onSelected: (cd) {
                              device = cd;
                              Navigator.pop(context);
                            },
                          ),
                          subtitle: Text(cd.bleMacAddress.asMac),
                          //onTap: () {
                          //  if (cd.state == BleDeviceState.connected) {
                          //    device = cd;
                          //    Navigator.pop(context);
                          //  } else {
                          //    cd.connect();
                          //  }
                          //},
                        );
                      },
                    )
                ],
              );
            },
          ),
        ),
      );
    }
  }
  return device;
}

class LDDialogAction {
  final String label;
  final bool filled;
  final void Function()? onTap;

  const LDDialogAction({required this.label, required this.filled, this.onTap});

  factory LDDialogAction.dismiss({bool filled = false}) =>
      LDDialogAction(label: 'Schließen'.i18n, filled: filled);

  factory LDDialogAction.cancel({bool filled = false}) =>
      LDDialogAction(label: 'Abbrechen'.i18n, filled: filled);

  factory LDDialogAction.save({bool filled = true, void Function()? onTap}) =>
      LDDialogAction(label: 'Speichern'.i18n, filled: filled, onTap: onTap);

  factory LDDialogAction.delete({bool filled = true, void Function()? onTap}) =>
      LDDialogAction(label: 'Löschen'.i18n, filled: filled, onTap: onTap);
}

Future<bool?> showLDDialog(
  BuildContext context, {
  Widget? content,
  required String title,
  required IconData icon,
  String? dismissLabel,
  Color? color,
  String? text,
  Widget? trailing,
  List<LDDialogAction>? actions,
}) async {
  actions ??= [LDDialogAction(label: dismissLabel ?? 'Schließen'.i18n, filled: true)];
  content ??= Text(text ?? '', textAlign: TextAlign.center);
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => Theme(
      data: color == null
          ? Theme.of(context)
          : Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: color,
                dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
              ),
              primaryColor: ColorScheme.fromSeed(
                seedColor: color,
                dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
              ).primary,
            ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Builder(builder: (context) {
          return AlertDialog(
            title: trailing == null
                ? Text(title)
                : Row(
                    children: [
                      const Spacer(flex: 1),
                      Text(title),
                      Expanded(
                        flex: 1,
                        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [trailing]),
                      ),
                    ],
                  ),
            icon: Icon(icon, color: Theme.of(context).primaryColor),
            actions: actions!
                .map(
                  (e) => TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      e.onTap?.call();
                    },
                    style: e.filled
                        ? ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).primaryColor,
                            ),
                          )
                        : null,
                    child: Text(
                      e.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: e.filled ? Colors.white : null,
                      ),
                    ),
                  ),
                )
                .toList(),
            content: content,
          );
        }),
      ),
    ),
  );
}

AppBar LDAppBar(BuildContext context, String title) {
  return AppBar(
    iconTheme: const IconThemeData(color: Colors.white),
    title: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/icon.png', width: 32, height: 32),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(title, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    ),
    backgroundColor: const Color(0xff2e88c1), //Theme.of(context).colorScheme.primary
  );
}
