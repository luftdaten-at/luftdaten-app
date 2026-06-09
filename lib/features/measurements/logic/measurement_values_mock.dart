import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

/// Rich mock point for comparing last-measurement UI layouts (debug only).
class MeasurementValuesMock {
  MeasurementValuesMock._();

  static MeasuredDataPoint samplePoint({DateTime? timestamp}) {
    return MeasuredDataPoint(
      timestamp: timestamp ?? DateTime(2026, 6, 8, 14, 32),
      sensorData: [
        SensorDataPoint(
          sensor: LDSensor.sen5x,
          values: {
            MeasurableQuantity.pm1: 8.2,
            MeasurableQuantity.pm25: 12.4,
            MeasurableQuantity.pm4: 14.1,
            MeasurableQuantity.pm10: 18.6,
            MeasurableQuantity.humidity: 55.0,
            MeasurableQuantity.temperature: 22.3,
            MeasurableQuantity.voc: 110,
            MeasurableQuantity.nox: 85,
          },
        ),
        SensorDataPoint(
          sensor: LDSensor.bme280,
          values: {
            MeasurableQuantity.temperature: 21.8,
            MeasurableQuantity.pressure: 1013.2,
            MeasurableQuantity.humidity: 53.0,
          },
        ),
        SensorDataPoint(
          sensor: LDSensor.scd4x,
          values: {
            MeasurableQuantity.co2: 850,
            MeasurableQuantity.temperature: 22.0,
            MeasurableQuantity.humidity: 54.0,
          },
        ),
        SensorDataPoint(
          sensor: LDSensor.bme680,
          values: {
            MeasurableQuantity.gasResistance: 145,
          },
        ),
      ],
    );
  }
}
