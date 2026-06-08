import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt_codec.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  test('mock GATT command path yields PM readings', () {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    MockBleGatt.initForDevice(device);

    MockBleGatt.writeCommand(device, [MockBleGattCodec.cmdReadSensorData]);
    final values = MockBleGattCodec.decodeSensorValuesBinary(
      MockBleGatt.readCharacteristic(device, BleGattUuids.sensorValues),
    );

    expect(values[MeasurableQuantity.pm25], isNotNull);
    expect(values[MeasurableQuantity.temperature], isNotNull);
  });
}
