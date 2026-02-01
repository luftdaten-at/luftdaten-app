import 'package:luftdaten.at/features/measurement/models/measured_data.dart';

class DeviceError {}

class SensorNotFoundError extends DeviceError {
  final LDSensor sensor;

  SensorNotFoundError(this.sensor);
}