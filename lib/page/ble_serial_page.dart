import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/controller/ble_controller.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/model/ble_device.dart';
import 'package:luftdaten.at/page/ble_serial_page.i18n.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class BLESerialPage extends StatefulWidget {
  const BLESerialPage({super.key});

  static const String route = 'serial';

  @override
  State<BLESerialPage> createState() => _BLESerialPageState();
}

class _BLESerialPageState extends State<BLESerialPage> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<int>>? _bleStream;
  final Uuid logUUID = Uuid.parse("424cf4bf-90ab-4333-8e4a-d15d677f56bd");
  Map<int, String> messages = {};
  BleDevice? device;
  List<String> strings = [];

  @override
  void initState() {
    super.initState();
    device = getIt<DeviceManager>().devices.firstWhere((e) => e.state == BleDeviceState.connected);
    BleController ble = getIt<BleController>();
    () async {
      while (device != null) {
        QualifiedCharacteristic qc = QualifiedCharacteristic(
            serviceId: ble.serviceId, characteristicId: logUUID, deviceId: device!.bleId!);
        bool modified = false;

        FlutterReactiveBle().readCharacteristic(qc).then((List<int> chars) {
          debugPrint("readLog: ${chars.length} / ${chars.length}");
          int off = 0;

          try {
            while (off + 3 < chars.length) {
              int index = chars[off++];
              int type = chars[off++];
              int len = chars[off++];
              String s = ascii.decode(chars.getRange(off, off + len).toList(), allowInvalid: true);
              off += len;
              if (messages[index] == null) {
                messages[index] = s;
                debugPrint("Msg: $index:$type:$len => $s");
                strings.add(s);
                modified = true;
              }
            }
          } catch (_, __) {
            debugPrint("Exception: $_ / $__");
          }
        });
        if (modified) {
          if(mounted) setState(() {});
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          await Future.delayed(const Duration(milliseconds: 3000));
        }
      }
    }();
  }

  @override
  void dispose() {
    device = null;
    _bleStream?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Serielle BLE-Konsole'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
              );
            },
            icon: const Icon(Icons.vertical_align_bottom, color: Colors.white),
            tooltip: 'Zum Ende scrollen'.i18n,
          )
        ],
      ),
      body: TableView.builder(
        columnCount: 1,
        rowCount: strings.length + 2,
        // Add 4 empty lines at the bottom for presentation
        columnBuilder: (int index) => const TableSpan(extent: FixedTableSpanExtent(1400)),
        rowBuilder: (int index) => const TableSpan(extent: FixedTableSpanExtent(20)),
        cellBuilder: (BuildContext _, TableVicinity vicinity) {
          if (vicinity.row >= strings.length) {
            return const TableViewCell(child: SizedBox(height: 0, width: 0));
          }
          String message = strings[vicinity.row];
          return TableViewCell(child: Text(message));
        },
        verticalDetails: ScrollableDetails.vertical(
          controller: _scrollController,
        ),
      ),
    );
  }
}
