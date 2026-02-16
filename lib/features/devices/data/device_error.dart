import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

class DeviceError {}

class SensorNotFoundError extends DeviceError {
  final LDSensor sensor;

  SensorNotFoundError(this.sensor);
}