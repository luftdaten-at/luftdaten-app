import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

class SensorDataPointWithTimestamp {
  const SensorDataPointWithTimestamp(this.timestamp, this.data);

  final DateTime timestamp;
  final SensorDataPoint data;
}
