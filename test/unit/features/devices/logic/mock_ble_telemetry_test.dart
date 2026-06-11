import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt_codec.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  test('mock GATT command path yields PM and SHTC3 climate readings for aRound', () {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    MockBleGatt.initForDevice(device);

    MockBleGatt.writeCommand(device, [MockBleGattCodec.cmdReadSensorData]);
    final blocks = MockBleGattCodec.decodeAllSensorBlocks(
      MockBleGatt.readCharacteristic(device, BleGattUuids.sensorValues),
    );

    expect(blocks.length, 2);
    expect(blocks[LDSensor.sen5x]![MeasurableQuantity.pm25], isNotNull);
    expect(blocks[LDSensor.sen5x]![MeasurableQuantity.temperature], isNotNull);
    expect(blocks[LDSensor.sen5x]![MeasurableQuantity.humidity], isNotNull);
    expect(blocks[LDSensor.shtc3]![MeasurableQuantity.temperature], isNotNull);
    expect(blocks[LDSensor.shtc3]![MeasurableQuantity.humidity], isNotNull);
  });
}
