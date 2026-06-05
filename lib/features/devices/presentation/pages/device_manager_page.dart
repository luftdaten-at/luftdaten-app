import 'dart:async';
import 'package:native_qr/native_qr.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/features/devices/logic/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_store.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/air_station_config_wizard_page.dart';
import 'package:luftdaten.at/core/widgets/dashboard_list_tile.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/device_detail_page.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_list_tile.dart';
import 'package:luftdaten.at/core/widgets/rotating_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:luftdaten.at/core/app/device_info.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/mock_ble_devices_page.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'device_manager_page.i18n.dart';


class DeviceManagerPage extends StatefulWidget {
  const DeviceManagerPage({super.key});

  static const String route = 'device-manager';

  @visibleForTesting
  static BleStatus? debugBleStatus;

  @visibleForTesting
  static void resetForTests() {
    _DeviceManagerPageState.initialScan = false;
    debugBleStatus = null;
  }

  @override
  State<DeviceManagerPage> createState() => _DeviceManagerPageState();
}

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
          BleStatus bleState =
              DeviceManagerPage.debugBleStatus ?? stream.data ?? BleStatus.unknown;
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
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Du hast noch kein Gerät aktiviert. Verwende die Funktion "Gerät hinzufügen" und scanne den QR Code deines Geräts'
                                .i18n,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                    DashboardListTile(
                      title: 'Neues Gerät hinzufügen'.i18n,
                      onTap: () => Navigator.pushNamed(context, QRCodePage.route),
                    ),
                    if (AppSettings.mockBleActive && DeviceInfo.isSimulator)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextButton(
                          onPressed: () async {
                            await Navigator.pushNamed(context, MockBleDevicesPage.route);
                            setState(() {});
                          },
                          child: Text('Mock-Gerät hinzufügen'.i18n),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              Consumer<DeviceManager>(
                builder: (context, manager, _) {
                  if (!manager.scanning) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Suche Bluetooth-Geräte…'.i18n,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(child: _buildDeviceList()),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<DeviceManager>(
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
            elevation: 2,
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
      bottomNavigationBar: Material(
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
            children: [
              if (AppSettings.mockBleActive && DeviceInfo.isSimulator)
                IconButton(
                  tooltip: 'Mock-Geräte verwalten'.i18n,
                  onPressed: () async {
                    await Navigator.pushNamed(context, MockBleDevicesPage.route);
                    setState(() {});
                  },
                  icon: const Icon(Icons.science_outlined),
                ),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
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
                                    builder: (_) =>
                                        AirStationConfigWizardPage(controller: controller)),
                              );
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    final devices = getIt<DeviceManager>().devices;
    final sections = <Widget>[];

    void addSection(String title, List<BleDevice> group, {required bool isStation}) {
      if (group.isEmpty) return;
      sections.add(DashboardSectionHeading(title: title));
      for (final device in group) {
        sections.add(
          DeviceListTile(
            device: device,
            isStation: isStation,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeviceDetailPage(device: device, isStation: isStation),
                ),
              );
            },
          ),
        );
      }
      sections.add(const SizedBox(height: 12));
    }

    addSection(
      'Air aRound',
      devices.where((e) => e.model == LDDeviceModel.aRound).toList(),
      isStation: false,
    );
    addSection(
      'Air Badge',
      devices.where((e) => e.model == LDDeviceModel.badge).toList(),
      isStation: false,
    );
    addSection(
      'Air Bike',
      devices.where((e) => e.model == LDDeviceModel.bike).toList(),
      isStation: false,
    );
    addSection(
      'Air Cube',
      devices.where((e) => e.model == LDDeviceModel.cube).toList(),
      isStation: false,
    );
    addSection(
      'Air Station',
      devices.where((e) => e.model == LDDeviceModel.station).toList(),
      isStation: true,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections,
      ),
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAndLaunchScanner());
  }

  Future<void> _initAndLaunchScanner() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (mounted) setState(() => missingCameraPermission = true);
        return;
      }
    }
    if (!mounted) return;
    await _scanQrCode();
  }

  Future<void> _scanQrCode() async {
    try {
      final nativeQr = NativeQr();
      final result = await nativeQr.get();
      if (!mounted) return;
      final dev = getIt<DeviceManager>().addDeviceByCode(result);
      if (dev != null) {
        Navigator.of(context).pop(dev);
      } else {
        Navigator.of(context).pop();
      }
    } catch (err) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text("Gerät hinzufügen".i18n, style: const TextStyle(color: Colors.white)),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
        ),
        body: missingCameraPermission
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "Die Luftdaten.at App braucht Zugriff auf ihre Kamera".i18n,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => openAppSettings(),
                        child: Text('Einstellungen öffnen'.i18n),
                      ),
                    ],
                  ),
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text('QR-Code Scannen'.i18n, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
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
            onPressed: () async {
              widget.device.measurementInterval = measuringIntervalInternal;
              if (nameController.text.isNotEmpty && editingName) {
                widget.device.userAssignedName = nameController.text;
              }
              await DeviceConfigStore.instance.writePortableConfig(
                PortableDeviceConfig(
                  bleName: widget.device.bleName,
                  measurementInterval: measuringIntervalInternal,
                  autoReconnect: widget.device.autoReconnect,
                  userAssignedName: widget.device.userAssignedName,
                  lastConfiguredAt: DateTime.now(),
                ),
              );
              if (!context.mounted) return;
              Navigator.pop(context);
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
