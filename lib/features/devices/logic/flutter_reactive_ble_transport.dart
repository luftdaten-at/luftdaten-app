import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';

class FlutterReactiveBleTransport implements BleGattTransport {
  FlutterReactiveBleTransport._();

  static final FlutterReactiveBleTransport instance = FlutterReactiveBleTransport._();

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  @override
  Future<List<int>> readCharacteristic({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
  }) {
    return _ble.readCharacteristic(
      QualifiedCharacteristic(
        serviceId: serviceId,
        characteristicId: characteristicId,
        deviceId: deviceId,
      ),
    );
  }

  @override
  Future<void> writeCharacteristicWithoutResponse({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
    required List<int> value,
  }) {
    return _ble.writeCharacteristicWithoutResponse(
      QualifiedCharacteristic(
        serviceId: serviceId,
        characteristicId: characteristicId,
        deviceId: deviceId,
      ),
      value: value,
    );
  }
}
