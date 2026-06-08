import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Luftdaten custom GATT service and characteristic UUIDs (firmware v2).
/// See https://github.com/luftdaten-at/firmware/blob/main/docs/ble-characteristics.md
abstract final class BleGattUuids {
  static final service = Uuid.parse('0931b4b5-2917-4a8d-9e72-23103c09ac29');
  static final deviceInfo = Uuid.parse('8d473240-13cb-1776-b1f2-823711b3ffff');
  static final sensorInfo = Uuid.parse('13fa8751-57af-4597-a0bb-b202f6111ae6');
  static final command = Uuid.parse('030ff8b1-1e45-4ae6-bf36-3bca4c38cdba');
  static final sensorValues = Uuid.parse('4b439140-73cb-4776-b1f2-8f3711b3bb4f');
  static final deviceStatus = Uuid.parse('77db81d9-9773-49b4-aa17-16a2f93e95f2');
  static final airStationConfiguration =
      Uuid.parse('b47b0cdf-0ced-49a9-86a5-d78a03ea7674');
  static final sdLogExport = Uuid.parse('51d2f8a4-91c6-53b2-a6e5-71829304a505');
}

/// Abstraction over real BLE reads/writes (used by [BleControllerV2] and mock GATT).
abstract class BleGattTransport {
  Future<List<int>> readCharacteristic({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
  });

  Future<void> writeCharacteristicWithoutResponse({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
    required List<int> value,
  });
}
