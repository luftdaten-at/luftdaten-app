import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/features/measurement/models/measured_data.dart';
import 'package:luftdaten.at/widget/marker_dialog.i18n.dart';

import 'package:luftdaten.at/shared/utils/gradient_color.dart';

class MarkerDialog extends StatefulWidget {
  const MarkerDialog(
      {super.key, required this.item, required this.values, this.controller, this.isInfo = false});

  final MeasuredDataPoint item;
  final List<FormattedValue> values;
  final MarkerDialogController? controller;
  final bool isInfo;

  @override
  State<StatefulWidget> createState() => _MarkerDialogState();
}

class _MarkerDialogState extends State<MarkerDialog> {
  Map<String, FormattedValue> data = {};
  List<String> pmVersions = [];
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    data = {for (var e in widget.values) e.entry: e};
    pmVersions = [
      if (data.containsKey('PM1.0')) 'PM1.0',
      if (data.containsKey('PM2.5')) 'PM2.5',
      if (data.containsKey('PM4.0')) 'PM4.0',
      if (data.containsKey('PM10.0')) 'PM10.0',
    ];
    widget.controller?._subscriber = this;
    controller.text = widget.item.annotation ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO apply a reasonable color, match with map. For now, use green.
    // Place values in a map sorted by dimension, then by sensor
    Map<MeasurableQuantity, Map<LDSensor, double>> values = {};
    for (SensorDataPoint sensorData in widget.item.sensorData) {
      for (MeasurableQuantity quantity in sensorData.values.keys) {
        if (!values.containsKey(quantity)) {
          values[quantity] = {};
        }
        values[quantity]![sensorData.sensor] = sensorData.values[quantity]!;
      }
    }

    // List sensors for which there are overlaps (two sensors provide the same value)
    List<LDSensor> sensorsWithOverlap = [];
    for (MeasurableQuantity quantity in values.keys) {
      if (values[quantity]!.length > 1) {
        for (LDSensor sensor in values[quantity]!.keys) {
          if (!sensorsWithOverlap.contains(sensor)) {
            sensorsWithOverlap.add(sensor);
          }
        }
      }
    }

    sensorsWithOverlap.sort((a, b) => a.index.compareTo(b.index));

    Map<LDSensor, String> sensorSymbols = {};
    for (int i = 0; i < sensorsWithOverlap.length; i++) {
      sensorSymbols[sensorsWithOverlap[i]] = '*' * (i + 1);
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('Gemessen: '.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('dd.MM.yyyy, HH:mm.').format(widget.item.timestamp)),
            ],
          ),
          if (pmVersions.isNotEmpty)
            Text('Feinstaub (μg/m³)'.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
          Table(
            children: [
              if (pmVersions.isNotEmpty)
                TableRow(
                  children: [
                    Text(pmVersions[0]),
                    Text(
                      data[pmVersions[0]]!.value,
                      style:
                          TextStyle(color: data[pmVersions[0]]!.color, fontWeight: FontWeight.bold),
                    ),
                    if (pmVersions.length > 1) Text(pmVersions[1]),
                    if (pmVersions.length > 1)
                      Text(
                        data[pmVersions[1]]!.value,
                        style: TextStyle(
                            color: data[pmVersions[1]]!.color, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              if (pmVersions.length > 2)
                TableRow(
                  children: [
                    Text(pmVersions[2]),
                    Text(
                      data[pmVersions[2]]!.value,
                      style:
                          TextStyle(color: data[pmVersions[2]]!.color, fontWeight: FontWeight.bold),
                    ),
                    if (pmVersions.length > 3) Text(pmVersions[3]),
                    if (pmVersions.length > 3)
                      Text(
                        data[pmVersions[3]]!.value,
                        style: TextStyle(
                            color: data[pmVersions[3]]!.color, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
            ],
          ),
          ..._buildValueRow(
            'NOx-Index (Relativ zu 100)'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.nox,
          ),
          ..._buildValueRow(
            'VOC-Index (Relativ zu 100)'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.voc,
          ),
          ..._buildValueRow(
            'VOCs (ppm)'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.totalVoc,
          ),
          ..._buildValueRow(
            'Temperatur'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.temperature,
            (val) => '$val°C',
          ),
          ..._buildValueRow(
            'Relative Luftfeuchtigkeit'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.humidity,
            (val) => '$val%',
          ),
          ..._buildValueRow(
            'Luftdruck (hPa)'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.pressure,
          ),
          ..._buildValueRow(
            'CO₂ (ppm)'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.co2,
          ),
          ..._buildValueRow(
            'O₃ (ppb)'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.o3,
          ),
          ..._buildValueRow(
            'Air Quality Index'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.aqi,
          ),
          ..._buildValueRow(
            'Gaswiderstand'.i18n,
            values,
            sensorSymbols,
            MeasurableQuantity.gasResistance,
          ),
          if (sensorsWithOverlap.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...sensorsWithOverlap.map((e) => Text('${sensorSymbols[e]} ${e.longName}')),
          ],
          if (!widget.isInfo) ...[
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Notizen hinzufügen'.i18n,
              ),
              minLines: 3,
              maxLines: 3,
              controller: controller,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildValueRow(
    String title,
    Map<MeasurableQuantity, Map<LDSensor, double>> values,
    Map<LDSensor, String> sensorSymbols,
    MeasurableQuantity dimension, [
    String Function(double)? formatter,
  ]) {
    if (!values.containsKey(dimension)) return [];
    Map<LDSensor, double> dimensionValues = values[dimension]!;
    if (dimensionValues.length == 1) {
      String formatted =
          formatter?.call(dimensionValues.values.first) ?? dimensionValues.values.first.toString();
      return [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          formatted,
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ];
    }
    List<Widget> valuesRow = [];
    for (LDSensor sensor in dimensionValues.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index))) {
      String formatted =
          formatter?.call(dimensionValues[sensor]!) ?? dimensionValues[sensor].toString();
      valuesRow.add(Text(
        formatted,
        style: TextStyle(color: getColor(dimension, dimensionValues[sensor]!), fontWeight: FontWeight.bold),
      ));
      valuesRow.add(Text(sensorSymbols[sensor]!));
      valuesRow.add(const SizedBox(width: 5));
    }
    return [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: valuesRow,
      ),
    ];
  }

  Color getColor(MeasurableQuantity dimension, double value) {
    switch(dimension) {
      case MeasurableQuantity.pm1:
        return GradientColor.pm1().getColor(value);
      case MeasurableQuantity.pm25:
        return GradientColor.pm25().getColor(value);
      case MeasurableQuantity.pm4:
        return GradientColor.pm4().getColor(value);
      case MeasurableQuantity.pm10:
        return GradientColor.pm10().getColor(value);
      case MeasurableQuantity.nox:
        return GradientColor.nox().getColor(value);
      case MeasurableQuantity.voc:
        return GradientColor.voc().getColor(value);
      case MeasurableQuantity.totalVoc:
        return GradientColor.totalVoc().getColor(value);
      case MeasurableQuantity.temperature:
        return GradientColor.temperature().getColor(value);
      case MeasurableQuantity.humidity:
        return GradientColor.humidity().getColor(value);
      case MeasurableQuantity.pressure:
        return GradientColor.pressure().getColor(value);
      case MeasurableQuantity.co2:
        return GradientColor.co2().getColor(value);
      case MeasurableQuantity.o3:
        return GradientColor.o3().getColor(value);
      case MeasurableQuantity.aqi:
        return GradientColor.aqi().getColor(value);
      case MeasurableQuantity.gasResistance:
        return GradientColor.gasResistance().getColor(value);
      default:
        return Colors.grey.shade900;
    }
  }

  @override
  void dispose() {
    widget.controller?._subscriber = null;
    super.dispose();
  }

  void saveChanges() {
    widget.item.annotation = controller.text.isEmpty ? null : controller.text;
  }
}

class MarkerDialogController extends ChangeNotifier {
  _MarkerDialogState? _subscriber;

  void saveChanges() {
    _subscriber?.saveChanges();
  }
}
