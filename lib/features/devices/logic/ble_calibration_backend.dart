import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

enum BleCalibrationStatus {
  success,
  unsupported,
  failed,
}

class BleCalibrationResult {
  const BleCalibrationResult({
    required this.status,
    this.message,
  });

  final BleCalibrationStatus status;
  final String? message;

  bool get isSuccess => status == BleCalibrationStatus.success;
  bool get isUnsupported => status == BleCalibrationStatus.unsupported;
}

/// Extension point for firmware-driven sensor calibration (e.g. SCD4x FRC).
abstract class BleCalibrationBackend {
  bool supportsForcedCo2Recal(LDSensor sensor);

  Future<BleCalibrationResult> runForcedCo2Recal({
    required BleDevice device,
    required LDSensor sensor,
  });
}

class DefaultBleCalibrationBackend implements BleCalibrationBackend {
  @override
  bool supportsForcedCo2Recal(LDSensor sensor) => false;

  @override
  Future<BleCalibrationResult> runForcedCo2Recal({
    required BleDevice device,
    required LDSensor sensor,
  }) async {
    return const BleCalibrationResult(
      status: BleCalibrationStatus.unsupported,
    );
  }
}
