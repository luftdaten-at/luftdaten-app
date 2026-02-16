import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/utils/list_extensions.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';

import 'nearby_devices_debug_page.i18n.dart';

class NearbyDevicesDebugPage extends StatefulWidget {
  const NearbyDevicesDebugPage({super.key});

  static const route = 'nearby-devices-debug';

  @override
  State<NearbyDevicesDebugPage> createState() => _NearbyDevicesDebugPageState();
}

class _NearbyDevicesDebugPageState extends State<NearbyDevicesDebugPage> {
  @override
  Widget build(BuildContext context) {
    if (FlutterReactiveBle().status != BleStatus.ready) {}
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('BLE-Scanner'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (!getIt<DeviceManager>().scanning) {
                getIt<DeviceManager>().scanForDevices(2000);
              }
            },
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: 'Neu scannen'.i18n,
          ),
        ],
      ),
      body: ChangeNotifierBuilder(
        notifier: getIt<DeviceManager>(),
        builder: (context, provider) {
          if (provider.scanning) {
            return Center(
              child: SpinKitDualRing(
                color: Theme.of(context).primaryColor,
                size: 40,
                lineWidth: 3,
              ),
            );
          } else {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 40),
                child: Column(
                  children: provider.deviceNamesFoundAtLastScan
                      .map<Widget>((e) => ListTile(
                            title: Text(
                              e,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList()
                      .spaceWith(const Divider(height: 1)),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
