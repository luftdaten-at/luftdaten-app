import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';

class FlutterReactiveBleTransport implements BleGattTransport {
  FlutterReactiveBleTransport._();

  static final FlutterReactiveBleTransport instance = FlutterReactiveBleTransport._();

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  QualifiedCharacteristic _qc({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
  }) {
    return QualifiedCharacteristic(
      serviceId: serviceId,
      characteristicId: characteristicId,
      deviceId: deviceId,
    );
  }

  @override
  Future<List<int>> readCharacteristic({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
  }) {
    return _ble.readCharacteristic(
      _qc(deviceId: deviceId, serviceId: serviceId, characteristicId: characteristicId),
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
      _qc(deviceId: deviceId, serviceId: serviceId, characteristicId: characteristicId),
      value: value,
    );
  }

  @override
  Future<void> writeCharacteristicWithResponse({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
    required List<int> value,
  }) {
    return _ble.writeCharacteristicWithResponse(
      _qc(deviceId: deviceId, serviceId: serviceId, characteristicId: characteristicId),
      value: value,
    );
  }

  @override
  Stream<List<int>> subscribeCharacteristic({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
  }) {
    return _ble
        .subscribeToCharacteristic(
          _qc(deviceId: deviceId, serviceId: serviceId, characteristicId: characteristicId),
        )
        .map((event) => event);
  }

  @override
  Future<int> requestMtu({
    required String deviceId,
    required int mtu,
  }) {
    return _ble.requestMtu(deviceId: deviceId, mtu: mtu);
  }
}
