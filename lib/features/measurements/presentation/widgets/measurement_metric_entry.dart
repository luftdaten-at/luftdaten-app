import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/domain/dimensions.dart' as dim;
import 'package:luftdaten.at/core/utils/gradient_color.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

enum MeasurementValueCategory {
  particulate,
  climate,
  gases,
}

class MeasurementMetricEntry {
  const MeasurementMetricEntry({
    required this.quantity,
    required this.value,
    required this.sensor,
    required this.statusColor,
    required this.formattedValue,
    required this.sensorSymbol,
  });

  final MeasurableQuantity quantity;
  final double value;
  final LDSensor sensor;
  final Color statusColor;
  final String formattedValue;
  final String sensorSymbol;

  String get label => quantity.name;

  String get unit => quantity.csvUnit;

  MeasurementValueCategory get category => switch (quantity) {
        MeasurableQuantity.pm01 ||
        MeasurableQuantity.pm1 ||
        MeasurableQuantity.pm25 ||
        MeasurableQuantity.pm4 ||
        MeasurableQuantity.pm10 =>
          MeasurementValueCategory.particulate,
        MeasurableQuantity.temperature ||
        MeasurableQuantity.humidity ||
        MeasurableQuantity.pressure =>
          MeasurementValueCategory.climate,
        _ => MeasurementValueCategory.gases,
      };

  String get sensorHint =>
      sensorSymbol.isEmpty ? sensor.shortName : '$sensorSymbol ${sensor.shortName}';
}

class MeasurementMetricParser {
  MeasurementMetricParser._();

  static List<MeasurementMetricEntry> fromDataPoint(MeasuredDataPoint point) {
    final values = <MeasurableQuantity, Map<LDSensor, double>>{};
    for (final sensorData in point.sensorData) {
      for (final quantity in sensorData.values.keys) {
        values.putIfAbsent(quantity, () => {});
        values[quantity]![sensorData.sensor] = sensorData.values[quantity]!;
      }
    }

    final sensorsWithOverlap = <LDSensor>{};
    for (final dimensionValues in values.values) {
      if (dimensionValues.length > 1) {
        sensorsWithOverlap.addAll(dimensionValues.keys);
      }
    }
    final sortedOverlap = sensorsWithOverlap.toList()..sort((a, b) => a.index.compareTo(b.index));
    final sensorSymbols = {
      for (var i = 0; i < sortedOverlap.length; i++) sortedOverlap[i]: '*' * (i + 1),
    };

    final entries = <MeasurementMetricEntry>[];
    for (final quantity in _displayOrder) {
      final dimensionValues = values[quantity];
      if (dimensionValues == null) continue;
      for (final sensor in dimensionValues.keys.toList()
        ..sort((a, b) => a.index.compareTo(b.index))) {
        final value = dimensionValues[sensor]!;
        entries.add(
          MeasurementMetricEntry(
            quantity: quantity,
            value: value,
            sensor: sensor,
            statusColor: statusColor(quantity, value),
            formattedValue: _formatValue(quantity, value),
            sensorSymbol: sensorSymbols[sensor] ?? '',
          ),
        );
      }
    }
    return entries;
  }

  static const _displayOrder = [
    MeasurableQuantity.pm1,
    MeasurableQuantity.pm25,
    MeasurableQuantity.pm4,
    MeasurableQuantity.pm10,
    MeasurableQuantity.nox,
    MeasurableQuantity.voc,
    MeasurableQuantity.totalVoc,
    MeasurableQuantity.temperature,
    MeasurableQuantity.humidity,
    MeasurableQuantity.pressure,
    MeasurableQuantity.co2,
    MeasurableQuantity.o3,
    MeasurableQuantity.aqi,
    MeasurableQuantity.gasResistance,
  ];

  static String _formatValue(MeasurableQuantity quantity, double value) {
    if (quantity == MeasurableQuantity.aqi) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  static Color statusColor(MeasurableQuantity dimension, double value) {
    switch (dimension) {
      case MeasurableQuantity.pm1:
        return dim.Dimension.getColor(dim.Dimension.PM1_0, value) as Color;
      case MeasurableQuantity.pm25:
        return dim.Dimension.getColor(dim.Dimension.PM2_5, value) as Color;
      case MeasurableQuantity.pm4:
        return dim.Dimension.getColor(dim.Dimension.PM4_0, value) as Color;
      case MeasurableQuantity.pm10:
        return dim.Dimension.getColor(dim.Dimension.PM10_0, value) as Color;
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
        return Colors.grey.shade700;
    }
  }
}
