import 'package:luftdaten.at/features/devices/data/sensor_details.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

enum CalibrationCapability {
  co2FreshAir,
  temperatureOffset,
  humidityOffset,
  bodyHeat,
}

/// Describes one calibratable quantity on a specific sensor.
class CalibratableQuantity {
  const CalibratableQuantity({
    required this.sensor,
    required this.quantity,
    required this.capability,
  });

  final LDSensor sensor;
  final MeasurableQuantity quantity;
  final CalibrationCapability capability;
}

abstract final class SensorCalibrationPolicy {
  static const co2Sensors = {LDSensor.scd4x};

  static const climateOffsetSensors = {
    LDSensor.sen5x,
    LDSensor.bme280,
    LDSensor.bme680,
    LDSensor.scd4x,
    LDSensor.aht20,
    LDSensor.sht30,
    LDSensor.sht31,
    LDSensor.sht35,
    LDSensor.sht4x,
    LDSensor.dht22,
    LDSensor.bmp280,
    LDSensor.bmp388,
    LDSensor.bmp390,
    LDSensor.bmp581,
    LDSensor.sen63c,
  };

  static bool supportsQuantityOffset(LDSensor sensor, MeasurableQuantity quantity) {
    if (quantity == MeasurableQuantity.co2) {
      return co2Sensors.contains(sensor);
    }
    if (quantity == MeasurableQuantity.temperature) {
      if (sensor == LDSensor.shtc3) return false;
      return climateOffsetSensors.contains(sensor);
    }
    if (quantity == MeasurableQuantity.humidity) {
      if (sensor == LDSensor.shtc3) return false;
      return climateOffsetSensors.contains(sensor);
    }
    return false;
  }

  static bool hasBodyHeatCalibration(Iterable<LDSensor> sensors) {
    return sensors.contains(LDSensor.shtc3);
  }

  static List<CalibrationCapability> capabilitiesFor(List<SensorDetails>? sensors) {
    if (sensors == null || sensors.isEmpty) return const [];

    final capabilities = <CalibrationCapability>{};
    final models = sensors.map((s) => s.model).toSet();

    if (models.any(co2Sensors.contains)) {
      capabilities.add(CalibrationCapability.co2FreshAir);
    }
    if (hasBodyHeatCalibration(models)) {
      capabilities.add(CalibrationCapability.bodyHeat);
    }
    for (final sensor in models) {
      if (supportsQuantityOffset(sensor, MeasurableQuantity.temperature)) {
        capabilities.add(CalibrationCapability.temperatureOffset);
      }
      if (supportsQuantityOffset(sensor, MeasurableQuantity.humidity)) {
        capabilities.add(CalibrationCapability.humidityOffset);
      }
    }

    return CalibrationCapability.values
        .where(capabilities.contains)
        .toList(growable: false);
  }

  static List<CalibratableQuantity> calibratableQuantities(List<SensorDetails> sensors) {
    final items = <CalibratableQuantity>[];
    for (final details in sensors) {
      for (final quantity in details.measuresQuantities) {
        if (!supportsQuantityOffset(details.model, quantity)) continue;
        final capability = switch (quantity) {
          MeasurableQuantity.co2 => CalibrationCapability.co2FreshAir,
          MeasurableQuantity.temperature => CalibrationCapability.temperatureOffset,
          MeasurableQuantity.humidity => CalibrationCapability.humidityOffset,
          _ => null,
        };
        if (capability == null) continue;
        items.add(
          CalibratableQuantity(
            sensor: details.model,
            quantity: quantity,
            capability: capability,
          ),
        );
      }
    }
    return items;
  }

  static LDSensor? co2SensorOnDevice(List<SensorDetails> sensors) {
    for (final details in sensors) {
      if (co2Sensors.contains(details.model) &&
          details.measuresQuantities.contains(MeasurableQuantity.co2)) {
        return details.model;
      }
    }
    return null;
  }
}
