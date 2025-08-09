import '../measurement/measured_data.dart';

class DeviceError {}

class SensorNotFoundError extends DeviceError {
  final LDSensor sensor;

  SensorNotFoundError(this.sensor);
}