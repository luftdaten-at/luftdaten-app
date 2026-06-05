import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/device_manager_page.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_connect_button.dart';

import 'mock_ble_devices_page.i18n.dart';

class MockBleDevicesPage extends StatefulWidget {
  const MockBleDevicesPage({super.key});

  static const String route = 'mock-ble-devices';

  @override
  State<MockBleDevicesPage> createState() => _MockBleDevicesPageState();
}

class _MockBleDevicesPageState extends State<MockBleDevicesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Mock-BLE-Geräte'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
      ),
      body: ListenableBuilder(
        listenable: AppSettings.I,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: Text('Mock-BLE aktiv'.i18n),
                subtitle: Text(
                  'Simuliert Verbindung und Messwerte ohne echtes Bluetooth (nur Debug-Build).'
                      .i18n,
                ),
                value: AppSettings.I.mockBleDevicesEnabled,
                onChanged: kDebugMode
                    ? (v) => setState(() => AppSettings.I.mockBleDevicesEnabled = v)
                    : null,
              ),
              const SizedBox(height: 8),
              if (!AppSettings.mockBleActive)
                Text('Mock-BLE ist deaktiviert. Schalte es oben ein.'.i18n)
              else ...[
                FilledButton(
                  onPressed: () {
                    getIt<DeviceManager>().addMockDevice(LDDeviceModel.aRound);
                    setState(() {});
                  },
                  child: Text('Air aRound hinzufügen'.i18n),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    getIt<DeviceManager>().addMockDevice(LDDeviceModel.station);
                    setState(() {});
                  },
                  child: Text('Air Station hinzufügen'.i18n),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {
                    getIt<DeviceManager>().addMockPresetBundle();
                    setState(() {});
                  },
                  child: Text('Beide Presets'.i18n),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await Navigator.pushNamed(context, QRCodeManualEntryPage.route);
                    setState(() {});
                  },
                  child: Text('Manuelle QR-Daten…'.i18n),
                ),
                const SizedBox(height: 24),
                Text(
                  'Gespeicherte Mock-Geräte'.i18n,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ChangeNotifierBuilder(
                  notifier: getIt<DeviceManager>(),
                  builder: (context, manager) {
                    final mocks = manager.devices.where((d) => d.isMock).toList();
                    if (mocks.isEmpty) {
                      return Text('Keine Mock-Geräte. Füge ein Preset hinzu.'.i18n);
                    }
                    return Column(
                      children: mocks
                          .map(
                            (d) => Card(
                              child: ListTile(
                                title: Text(d.displayName),
                                subtitle: Text(d.bleName),
                                trailing: SizedBox(
                                  width: 110,
                                  child: DeviceConnectButton(device: d),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
