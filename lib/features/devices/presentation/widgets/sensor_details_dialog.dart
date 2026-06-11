import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';

import '../pages/device_detail_page.i18n.dart';

Future<bool?> showSensorDetailsDialog(BuildContext context, SensorDetails details) {
  final rows = <Widget>[
    Text(
      details.model.longName.i18n,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    Text('Misst: %s'.i18n.fill([
      details.measuresQuantities.map((e) => e.name).join(', '),
    ])),
    if (details.serialNumber != null && details.serialNumber!.isNotEmpty)
      Text('Seriennummer: %s'.i18n.fill([details.serialNumber!])),
    if (details.firmwareVersion != null)
      Text('Sensor-Firmware: %s'.i18n.fill([details.firmwareVersion!])),
    if (details.hardwareVersion != null)
      Text('Hardware-Version: %s'.i18n.fill([details.hardwareVersion!])),
    if (details.protocolVersion != null)
      Text('Protokoll-Version: %s'.i18n.fill([details.protocolVersion!])),
  ];

  return showLDDialog(
    context,
    title: details.model.longName.i18n,
    icon: Icons.sensors,
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    ),
  );
}
