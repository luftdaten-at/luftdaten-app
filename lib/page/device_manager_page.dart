import 'dart:async';
import 'dart:collection';
import 'package:native_qr/native_qr.dart';

import 'package:flutter/foundation.dart';
import 'package:clipboard/clipboard.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:luftdaten.at/controller/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/model/battery_details.dart';
import 'package:luftdaten.at/page/air_station_config_wizard_page.dart';
import 'package:luftdaten.at/util/list_extensions.dart';
import 'package:luftdaten.at/widget/device_connect_button.dart';
import 'package:luftdaten.at/widget/rotating_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../controller/app_settings.dart';
import '../main.dart';
import '../model/ble_device.dart';
import '../widget/change_notifier_builder.dart';
import '../widget/ui.dart';
import 'device_manager_page.i18n.dart';


class DeviceManagerPage extends StatefulWidget {
  const DeviceManagerPage({super.key});

  static const String route = 'device-manager';

  @override
  State<DeviceManagerPage> createState() => _DeviceManagerPageState();
}

final HashMap<BleDeviceState, Color> devStateColors = HashMap.from({
  BleDeviceState.connecting: Colors.orange,
  BleDeviceState.connected: Colors.green,
  BleDeviceState.disconnected: Colors.red,
  BleDeviceState.discovered: Colors.blue,
  BleDeviceState.notFound: Colors.grey,
});
final HashMap<BleDeviceState, String> devStateStrings = HashMap.from({
  BleDeviceState.connecting: "Baue Verbindung auf...",
  BleDeviceState.connected: "Verbunden",
  BleDeviceState.disconnected: "Keine Verbindung",
  BleDeviceState.discovered: "Sichtbar",
  BleDeviceState.notFound: "Nicht in der Nähe",
  BleDeviceState.unknown: "Nicht in der Nähe",
});

class _DeviceManagerPageState extends State<DeviceManagerPage> {
  static bool initialScan = false;
  RotatingWidgetController syncIconController = RotatingWidgetController();

  void connectTo(BleDevice device) async {
    logger.d("Connecting to ${device.bleName}");
    device.connect();
  }

  void addDevice(BuildContext context) async {
    assert(false);
    var status = await Permission.camera.status;
    logger.d("Status = $status");
    var perm = await Permission.camera.request();
    if (perm.isDenied) {
      logger.d("Permission not granted yet: $perm");
      if (context.mounted) {
        showLDDialog(
          context,
          content: Text("Die Luftdaten.at App braucht Zugriff auf ihre Kamera".i18n),
          title: 'Kamera-Berechtigung'.i18n,
          actions: [
            LDDialogAction.dismiss(filled: false),
            LDDialogAction(
                label: 'Erteilen'.i18n,
                filled: true,
                onTap: () {
                  openAppSettings();
                }),
          ],
          icon: Icons.camera_alt,
        );
      }
    } else {
      if (context.mounted) {
        Navigator.pushNamed(context, QRCodePage.route);
      }
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    String? errorMsg;

    return Scaffold(
      body: StreamBuilder(
        stream: FlutterReactiveBle().statusStream,
        builder: (context, stream) {
          BleStatus bleState = stream.data ?? BleStatus.unknown;
          if (kDebugMode) {
            logger.d("BLE_state = $bleState");
          }
          if (bleState != BleStatus.ready) {
            errorMsg = bleState == BleStatus.unsupported
                ? "Dieses Gerät unterstützt Bluetooth nicht".i18n
                : bleState == BleStatus.unauthorized
                    ? "Die Luftdaten.at App braucht Zugriff auf Bluetooth und den Standort".i18n
                    : bleState == BleStatus.poweredOff
                        ? "Bluetooth ist ausgeschalten. Um diese App zu nutzen muss es eingeschalten werden"
                            .i18n
                        : bleState == BleStatus.locationServicesDisabled
                            ? "Die Standort-Erkennung (GPS) muss eingeschaltet werden".i18n
                            : "Versuche aktuellen Bluetooth Status ($bleState) zu erkennen";
            if (!(bleState == BleStatus.unsupported && getIt<DeviceManager>().devices.isNotEmpty)) {
              // Erlaubt es, manuell auf dem Simulator hinzugefügte Geräte anzuzeigen
              // (Auf echten Geräten sollte dieser Fall außerhalb von Tests nie eintreten)
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Center(child: Text(errorMsg!, textAlign: TextAlign.center)),
              );
            }
          } else if (!initialScan) {
            // TODO move this higher-up, scanning shouldn't only happen when we open Device Manager
            initialScan = true;
            //Future.delayed(const Duration(milliseconds: 500)).then((_) {
            //  getIt<BleController>().scanForDevices(3000);
            //});
          }

          if (getIt<DeviceManager>().devices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Du hast noch kein Gerät aktiviert. Verwende die Funktion "Gerät hinzufügen" und scanne den QR Code deines Geräts'
                      .i18n,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _buildDeviceList();
        },
      ),
      floatingActionButton: const SizedBox() ?? Consumer<DeviceManager>(
        builder: (ctx, provider, _) {
          logger.d('Rebuilt with status ${provider.scanning}');
          if (provider.scanning) {
            syncIconController.start();
          } else {
            syncIconController.stop();
          }
          return FloatingActionButton(
            heroTag: "devManMain",
            onPressed: provider.scanning ? null : () => provider.scanForDevices(2000),
            backgroundColor: Colors.white,
            tooltip: 'Nach Bluetooth-Geräten scannen'.i18n,
            child: RotatingWidget(
              controller: syncIconController,
              duration: const Duration(milliseconds: 600),
              activeChild: Icon(Icons.sync, color: Colors.grey.shade400),
              child: const Icon(Icons.sync, color: Colors.black),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.blue.withOpacity(0.5),
        child: FilledButton.tonalIcon(
          label: Text("Neues Gerät hinzufügen".i18n),
          icon: const Icon(Icons.qr_code),
          onPressed: () async {
            BleDevice? addedDevice =
                await Navigator.pushNamed(context, QRCodePage.route) as BleDevice?;
            setState(() {});
            await Future.delayed(Duration.zero);
            if (addedDevice?.model == LDDeviceModel.station && context.mounted) {
              // Turn on the dashboard Air Stations tab
              AppSettings.I.dashboardShowAirStations = true;
              showLDDialog(
                context,
                title: 'Air Station einrichten'.i18n,
                icon: Icons.settings_outlined,
                text: 'Neue Air Station-Geräte müssen konfiguriert werden, um sich mit dem WLAN '
                        'zu verbinden. Jetzt konfigurieren?'
                    .i18n,
                actions: [
                  LDDialogAction(label: 'Später'.i18n, filled: false),
                  LDDialogAction(
                    label: 'Konfigurieren'.i18n,
                    filled: true,
                    onTap: () {
                      AirStationConfigWizardController controller =
                          AirStationConfigWizardController(addedDevice!.bleName);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => AirStationConfigWizardPage(controller: controller)),
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    DeviceManager deviceManager = getIt<DeviceManager>();
    List<BleDevice> devices = deviceManager.devices;
    List<BleDevice> airARoundDevices =
        devices.where((e) => e.model == LDDeviceModel.aRound).toList();
    List<BleDevice> airBadgeDevices = devices.where((e) => e.model == LDDeviceModel.badge).toList();
    List<BleDevice> airBikeDevices = devices.where((e) => e.model == LDDeviceModel.bike).toList();
    List<BleDevice> airCubeDevices = devices.where((e) => e.model == LDDeviceModel.cube).toList();
    List<BleDevice> airStationDevices =
        devices.where((e) => e.model == LDDeviceModel.station).toList();
    bool initiallyExpanded = devices.length <= 5;
    return ListView(
      children: [
        ...<Widget>[
          if (airARoundDevices.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Row(
                  children: [
                    Text(
                      'Air aRound',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                initiallyExpanded: true,
                children:
                    airARoundDevices.map((e) => _buildPortableTile(e, initiallyExpanded)).toList(),
              ),
            ),
          if (airBadgeDevices.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Row(
                  children: [
                    Text(
                      'Air Badge',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                initiallyExpanded: true,
                children:
                    airBadgeDevices.map((e) => _buildPortableTile(e, initiallyExpanded)).toList(),
              ),
            ),
          if (airBikeDevices.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Row(
                  children: [
                    Text(
                      'Air Bike',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                initiallyExpanded: true,
                children:
                airBikeDevices.map((e) => _buildPortableTile(e, initiallyExpanded)).toList(),
              ),
            ),
          if (airCubeDevices.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Row(
                  children: [
                    Text(
                      'Air Cube',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                initiallyExpanded: true,
                children:
                    airCubeDevices.map((e) => _buildPortableTile(e, initiallyExpanded)).toList(),
              ),
            ),
          if (airStationDevices.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Row(
                  children: [
                    Text(
                      'Air Station',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                initiallyExpanded: true,
                children: airStationDevices
                    .map((e) => _buildAirStationTile(e, initiallyExpanded))
                    .toList(),
              ),
            ),
        ].spaceWithList([
          const SizedBox(height: 30),
          const Row(
            children: [
              SizedBox(width: 20),
              Expanded(child: Divider(height: 1)),
              SizedBox(width: 20),
            ],
          ),
          const SizedBox(height: 10),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPortableTile(BleDevice device, bool initiallyExpanded) {
    return ChangeNotifierBuilder(
        notifier: device,
        builder: (context, device) {
          String shortenedName = device.displayName.replaceAll('Air aRound ', '');
          return ColoredBox(
            color: device.state == BleDeviceState.connected
                ? Colors.green.shade50
                : Theme.of(context).scaffoldBackgroundColor,
            child: Material(
              child: ExpansionTile(
                initiallyExpanded: initiallyExpanded,
                title: Row(
                  children: [
                    const SizedBox(width: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: devStateColors[device.state] ?? Colors.black,
                        borderRadius: const BorderRadius.all(Radius.circular(6)),
                      ),
                      height: 12,
                      width: 12,
                    ),
                    const SizedBox(width: 2),
                    _getStatusBluetoothIcon(device.state),
                    const SizedBox(width: 5),
                    Text(shortenedName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    if (device.state == BleDeviceState.connected && device.batteryDetails != null)
                      ..._getBatteryIconAndText(device.batteryDetails!),
                    const Spacer(flex: 1),
                    DeviceConnectButton(device: device),
                  ],
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 18),
                                Text('Name: '.i18n),
                                Text(device.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 18),
                                Text('Adresse: '.i18n),
                                Text(device.bleMacAddress.asMac,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 18),
                                Text('Status: '.i18n),
                                Container(
                                  decoration: BoxDecoration(
                                    color: devStateColors[device.state] ?? Colors.black,
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                  ),
                                  height: 8,
                                  width: 8,
                                ),
                                Text(
                                  ' ${(devStateStrings[device.state] ?? 'Error').i18n}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: device.state == BleDeviceState.connected
                            ? () {
                                showLDDialog(
                                  context,
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          Row(mainAxisSize: MainAxisSize.min, children: [
                                            Text('Firmware-Version: '.i18n),
                                            Text(
                                              device.firmwareVersion.toString(),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ]),
                                          const SizedBox(height: 10),
                                          const Divider(height: 1),
                                          const SizedBox(height: 10),
                                          Text('Sensoren:'.i18n),
                                          if (device.availableSensors != null)
                                            ...device.availableSensors!.map((details) => Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            const SizedBox(height: 10),
                                                            Text(
                                                              details.model.longName.i18n,
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            Text('Misst: %s'.i18n.fill([
                                                              details.measuresQuantities
                                                                  .map((e) => e.name)
                                                                  .join(', ')
                                                            ])),
                                                            if (details.serialNumber != null)
                                                              Text('Seriennummer: %s'
                                                                  .i18n
                                                                  .fill([details.serialNumber!])),
                                                            if (details.firmwareVersion != null)
                                                              Text('Sensor-Firmware: %s'.i18n.fill(
                                                                  [details.firmwareVersion!])),
                                                            if (details.hardwareVersion != null)
                                                              Text('Hardware-Version: %s'.i18n.fill(
                                                                  [details.hardwareVersion!])),
                                                            if (details.protocolVersion != null)
                                                              Text('Protokoll-Version: %s'
                                                                  .i18n
                                                                  .fill(
                                                                      [details.protocolVersion!])),
                                                          ]),
                                                    ),
                                                  ],
                                                ))
                                        ],
                                      ),
                                    ],
                                  ),
                                  title: device.displayName,
                                  icon: Icons.info_outline,
                                );
                              }
                            : null,
                        icon: Icon(
                          Icons.info_outline,
                          color: device.state == BleDeviceState.connected
                              ? null
                              : Colors.grey.shade400,
                        ),
                        style: ButtonStyle(
                          backgroundColor: device.state == BleDeviceState.connected
                              ? MaterialStateProperty.all(Theme.of(context).primaryColor)
                              : MaterialStateProperty.all(Colors.grey.shade300),
                        ),
                        tooltip: 'Geräte-Info'.i18n,
                      ),
                      IconButton.filled(
                        onPressed: () {
                          if (device.portable) {
                            showDialog(
                                context: context,
                                builder: (_) => DeviceConfigDialog(device: device));
                          } else {
                            if (AirStationConfigWizardController.activeControllers
                                .containsKey(device.bleName)) {
                              AirStationConfigWizardController controller =
                                  AirStationConfigWizardController(device.bleName);
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => AirStationConfigWizardPage(
                                  controller: controller,
                                ),
                              ));
                              return;
                            }
                            showLDDialog(
                              context,
                              title: 'Station neu einrichten'.i18n,
                              icon: Icons.settings_outlined,
                              text:
                                  'Möchtest du die WLAN- oder Messeinstellungen der Air Station neu '
                                          'konfigurieren?'
                                      .i18n,
                              actions: [
                                LDDialogAction(label: 'Abbrechen'.i18n, filled: false),
                                LDDialogAction(
                                  label: 'Konfigurieren'.i18n,
                                  filled: true,
                                  onTap: () {
                                    AirStationConfigWizardController controller =
                                        AirStationConfigWizardController(device.bleName);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              AirStationConfigWizardPage(controller: controller)),
                                    );
                                  },
                                ),
                              ],
                            );
                            return;
                          }
                        },
                        icon: const Icon(Icons.settings),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Theme.of(context).primaryColor),
                        ),
                        tooltip: 'Gerät konfigurieren'.i18n,
                      ),
                      IconButton.filled(
                        onPressed: () {
                          showLDDialog(
                            context,
                            text:
                                '${'Gerät'.i18n} ${device.displayName} ${'aus der Geräteliste entfernen?'.i18n}',
                            title: 'Gerät löschen?'.i18n,
                            icon: Icons.delete,
                            actions: [
                              LDDialogAction(label: 'Behalten'.i18n, filled: false),
                              LDDialogAction(
                                label: 'Löschen'.i18n,
                                filled: true,
                                onTap: () {
                                  getIt<DeviceManager>().deleteDevice(device);
                                  setState(() {});
                                },
                              ),
                            ],
                            color: Colors.red,
                          );
                        },
                        icon: const Icon(Icons.delete),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.red),
                        ),
                        tooltip: 'Gerät entfernen'.i18n,
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildAirStationTile(BleDevice device, bool initiallyExpanded) {
    return ChangeNotifierBuilder(
        notifier: device,
        builder: (context, device) {
          String shortenedName = device.displayName;

          List<int> macBytes = hex.decode(device.bleMacAddress);
          macBytes[macBytes.length - 1] = macBytes[macBytes.length - 1] - 1;
          List<int> chipIdBytes = macBytes.reversed.toList();
          String chipId = hex.encode(chipIdBytes);

          return ColoredBox(
            color: device.state == BleDeviceState.connected
                ? Colors.green.shade50
                : Theme.of(context).scaffoldBackgroundColor,
            child: Material(
              child: ExpansionTile(
                initiallyExpanded: initiallyExpanded,
                title: Row(
                  children: [
                    Text(shortenedName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (_) => AirStationRenamingDialog(device: device));
                      },
                      icon: const Icon(Icons.draw),
                      padding: const EdgeInsets.all(0),
                      iconSize: 20,
                      tooltip: 'Umbenennen'.i18n,
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 18),
                                Text('Gerät: '.i18n),
                                Text(device.deviceOriginalDisplayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 18),
                                Text('Adresse: '.i18n),
                                Text(device.bleMacAddress.asMac,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 18),
                                Text('Sensor-ID: '.i18n),
                                Text(chipId, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 3),
                                InkWell(
                                  onTap: () {
                                    FlutterClipboard.copy(chipId);
                                    Fluttertoast.showToast(msg: 'Sensor-ID kopiert!'.i18n);
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.copy,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                InkWell(
                                  onTap: () {
                                    showLDDialog(
                                      context,
                                      title: 'Sensor-ID'.i18n,
                                      icon: Icons.help_outline_outlined,
                                      text: 'Die Sensor-ID wird benötigt, um die Station in der '
                                              'Sensor.Community einzutragen. Anweisungen hierzu findest '
                                              'du auf unserer Webseite.'
                                          .i18n,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(1),
                                    child: Icon(
                                      Icons.help_outline,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () {
                          if (device.portable) {
                            showDialog(
                                context: context,
                                builder: (_) => DeviceConfigDialog(device: device));
                          } else {
                            if (AirStationConfigWizardController.activeControllers
                                .containsKey(device.bleName)) {
                              AirStationConfigWizardController controller =
                                  AirStationConfigWizardController(device.bleName);
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => AirStationConfigWizardPage(
                                  controller: controller,
                                ),
                              ));
                              return;
                            }
                            showLDDialog(
                              context,
                              title: 'Station neu einrichten'.i18n,
                              icon: Icons.settings_outlined,
                              text:
                                  'Möchtest du die WLAN- oder Messeinstellungen der Air Station neu '
                                          'konfigurieren?'
                                      .i18n,
                              actions: [
                                LDDialogAction(label: 'Abbrechen'.i18n, filled: false),
                                LDDialogAction(
                                  label: 'Konfigurieren'.i18n,
                                  filled: true,
                                  onTap: () {
                                    AirStationConfigWizardController controller =
                                        AirStationConfigWizardController(device.bleName);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              AirStationConfigWizardPage(controller: controller)),
                                    );
                                  },
                                ),
                              ],
                            );
                            return;
                          }
                        },
                        icon: const Icon(Icons.settings),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Theme.of(context).primaryColor),
                        ),
                        tooltip: 'Gerät konfigurieren'.i18n,
                      ),
                      IconButton.filled(
                        onPressed: () {
                          showLDDialog(
                            context,
                            text:
                                '${'Gerät'.i18n} ${device.displayName} ${'aus der Geräteliste entfernen?'.i18n}',
                            title: 'Gerät löschen?'.i18n,
                            icon: Icons.delete,
                            actions: [
                              LDDialogAction(label: 'Behalten'.i18n, filled: false),
                              LDDialogAction(
                                label: 'Löschen'.i18n,
                                filled: true,
                                onTap: () {
                                  getIt<DeviceManager>().deleteDevice(device);
                                  setState(() {});
                                },
                              ),
                            ],
                            color: Colors.red,
                          );
                        },
                        icon: const Icon(Icons.delete),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.red),
                        ),
                        tooltip: 'Gerät entfernen'.i18n,
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _getStatusBluetoothIcon(BleDeviceState state) {
    switch (state) {
      case BleDeviceState.discovered:
      case BleDeviceState.disconnected:
        return const Icon(Icons.bluetooth, color: Colors.blue);
      case BleDeviceState.connecting:
        return const Icon(Icons.bluetooth_searching, color: Colors.blue);
      case BleDeviceState.connected:
        return const Icon(Icons.bluetooth_connected, color: Colors.blue);
      case BleDeviceState.error:
      case BleDeviceState.notFound:
      default:
        return const Icon(Icons.bluetooth_disabled_outlined, color: Colors.grey);
    }
  }

  List<Widget> _getBatteryIconAndText(BatteryDetails details) {
    Widget batteryIcon;
    Widget? batteryText;
    switch (details.status) {
      case BatteryStatus.unknown:
        batteryIcon = const SizedBox();
      case BatteryStatus.unsupported:
      case BatteryStatus.faulty:
        batteryIcon = const Icon(Icons.battery_unknown_outlined, color: Colors.grey);
      case BatteryStatus.charging:
        batteryIcon = const Icon(Icons.battery_charging_full_outlined, color: Colors.green);
      case BatteryStatus.discharging:
        // Depends on battery percentage
        double percentage = details.percentage ?? 0;
        if (percentage > 90) {
          batteryIcon = const Icon(Icons.battery_full, color: Colors.green);
          batteryText = Text('${details.percentage}%', style: const TextStyle(color: Colors.green));
        } else if (percentage > 70) {
          batteryIcon = const Icon(Icons.battery_5_bar, color: Colors.green);
          batteryText = Text('${details.percentage}%',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ));
        } else if (percentage > 40) {
          batteryIcon = const Icon(Icons.battery_4_bar, color: Colors.green);
          batteryText = Text('${details.percentage}%',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ));
        } else if (percentage > 20) {
          batteryIcon = const Icon(Icons.battery_2_bar, color: Colors.orange);
          batteryText = Text('${details.percentage}%',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ));
        } else {
          batteryIcon = const Icon(Icons.battery_alert, color: Colors.red);
          batteryText = Text('${details.percentage}%',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ));
        }
    }
    return [
      batteryIcon,
      if (batteryText != null) batteryText,
    ];
  }
}

class QRCodePage extends StatefulWidget {
  const QRCodePage({super.key});

  static const String route = 'qrcode';

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}


class _QRCodePageState extends State<QRCodePage> {
  bool missingCameraPermission = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission(); // Check camera permission on init
  }

  // Method to check camera permissions
  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        setState(() {
          missingCameraPermission = true; // Update the state to indicate missing permission
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gerät hinzufügen"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Aktion für QR Code Scannen
                try {
                  NativeQr nativeQr = NativeQr();
                  String? result = await nativeQr.get();
                  BleDevice? dev = getIt<DeviceManager>().addDeviceByCode(result); 
                  if (dev != null) {
                    Navigator.of(context).pop(dev);
                  }
                } catch(err) {
                  print(err);
                }
              },
              child: Text("QrCode Scannen"),
            ),
            SizedBox(height: 20), // Abstand zwischen den Buttons
            ElevatedButton(
              onPressed: () async {
                // Aktion für Daten manuell eingeben
                BleDevice? dev =
                await Navigator.pushNamed(context, QRCodeManualEntryPage.route) as BleDevice?;
                if (dev != null && context.mounted) {
                  Navigator.of(context).pop(dev);
                }
              },
              child: Text("Daten manuell eingeben"),
            ),
          ],
        ),
      ),
    );
  }
}

class QRCodeManualEntryPage extends StatefulWidget {
  const QRCodeManualEntryPage({super.key});

  static const String route = 'qrcode-manual';

  @override
  State<QRCodeManualEntryPage> createState() => _QRCodeManualEntryPageState();
}

class _QRCodeManualEntryPageState extends State<QRCodeManualEntryPage> {
  final TextEditingController _name = TextEditingController(), _id = TextEditingController();
  int selectedOption = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text("Neues Gerät hinzufügen".i18n, style: const TextStyle(color: Colors.white)),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Modell'.i18n,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                RadioMenuButton<int>(
                  value: 1,
                  groupValue: selectedOption,
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      selectedOption = val;
                    });
                  },
                  child: const Text('Air aRound'),
                ),
                RadioMenuButton<int>(
                  value: 3,
                  groupValue: selectedOption,
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      selectedOption = val;
                    });
                  },
                  child: const Text('Air Station'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Daten'.i18n,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    label: Text('Gerätename'.i18n),
                    hintText: 'Air aRound B000',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _id,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    label: Text('Kennnummer'.i18n),
                    hintText: 'Luftdaten.at-00112233AABB',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: FilledButton(
                          onPressed: (_name.text.isNotEmpty && _id.text.isNotEmpty)
                              ? () {
                                  BleDevice? dev = getIt<DeviceManager>().addDeviceByCode(
                                      '${_name.text};${_id.text};$selectedOption;1');
                                  if (dev != null) {
                                    setState(() {
                                      Navigator.of(context).pop(dev);
                                    });
                                  } else {
                                    showLDDialog(
                                      context,
                                      content: Text(
                                        'Überprüfe deine Eingaben.'.i18n,
                                        textAlign: TextAlign.center,
                                      ),
                                      title: 'Daten ungültig'.i18n,
                                      icon: Icons.error,
                                    );
                                  }
                                }
                              : null,
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                              (state) {
                                if (state.contains(MaterialState.disabled)) {
                                  return Colors.grey;
                                }
                                return Theme.of(context).primaryColor;
                              },
                            ),
                            foregroundColor: MaterialStateProperty.resolveWith(
                              (state) {
                                if (state.contains(MaterialState.disabled)) {
                                  return Colors.grey.shade200;
                                }
                                return Colors.white;
                              },
                            ),
                          ),
                          child: Text(
                            'Gerät hinzufügen'.i18n,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeviceConfigDialog extends StatefulWidget {
  const DeviceConfigDialog({super.key, required this.device});

  final BleDevice device;

  @override
  State<StatefulWidget> createState() => _DeviceConfigDialogState();
}

class _DeviceConfigDialogState extends State<DeviceConfigDialog> {
  int measuringIntervalInternal = 10;
  bool editingName = false;
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    measuringIntervalInternal = widget.device.measurementInterval;
    nameController.text = widget.device.displayName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: editingName
            ? Row(
                children: [
                  const Spacer(flex: 1),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Gerätname'.i18n,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              editingName = false;
                            });
                          },
                          icon: Icon(Icons.cancel, color: Theme.of(context).primaryColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        suffixIconConstraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              )
            : Row(
                children: [
                  const Spacer(flex: 1),
                  const SizedBox(width: 30),
                  Text(widget.device.displayName, textAlign: TextAlign.center),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 28,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          editingName = true;
                        });
                      },
                      icon: Icon(Icons.draw, color: Theme.of(context).primaryColor),
                      padding: const EdgeInsets.all(4),
                      iconSize: 20,
                      constraints: const BoxConstraints(),
                      tooltip: 'Gerätnamen ändern'.i18n,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
        icon: Icon(Icons.construction, color: Theme.of(context).primaryColor),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Messdaten abfragen alle'.i18n),
            DropdownButton<int>(
              items: [
                DropdownMenuItem(value: 2, child: Text('2 Sekunden'.i18n)),
                DropdownMenuItem(value: 5, child: Text('5 Sekunden'.i18n)),
                DropdownMenuItem(value: 10, child: Text('10 Sekunden'.i18n)),
                DropdownMenuItem(value: 20, child: Text('20 Sekunden'.i18n)),
                DropdownMenuItem(value: 30, child: Text('30 Sekunden'.i18n)),
                DropdownMenuItem(value: 60, child: Text('1 Minute'.i18n)),
              ],
              value: measuringIntervalInternal,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    measuringIntervalInternal = val;
                  });
                }
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: widget.device.autoReconnect,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        widget.device.autoReconnect = val;
                      });
                    }
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text('Automatisch verbinden'.i18n),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Abbrechen'.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.device.measurementInterval = measuringIntervalInternal;
              if (nameController.text.isNotEmpty && editingName) {
                widget.device.userAssignedName = nameController.text;
              }
              getIt<DeviceManager>().notifyListeners();
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
            ),
            child: Text(
              'Speichern'.i18n,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class AirStationRenamingDialog extends StatefulWidget {
  const AirStationRenamingDialog({super.key, required this.device});

  final BleDevice device;

  @override
  State<StatefulWidget> createState() => _AirStationRenamingDialogState();
}

class _AirStationRenamingDialogState extends State<AirStationRenamingDialog> {
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    nameController.text = widget.device.displayName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('Gerät umbenennen'.i18n),
        icon: Icon(Icons.draw, color: Theme.of(context).primaryColor),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Name'.i18n,
              ),
              maxLength: 20,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Abbrechen'.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (nameController.text.isNotEmpty) {
                widget.device.userAssignedName = nameController.text;
              }
              getIt<DeviceManager>().notifyListeners();
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
            ),
            child: Text(
              'Speichern'.i18n,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
