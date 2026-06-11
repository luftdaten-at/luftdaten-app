import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt_codec.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  group('MockBleGatt', () {
    late BleDevice device;

    setUp(() {
      device = BleDevice(
        model: LDDeviceModel.station,
        bleName: 'Luftdaten.at-000000000002',
        bleMacAddress: '000000000002',
        deviceOriginalDisplayName: 'Mock Station',
        isMock: true,
        bleId: 'mock:Luftdaten.at-000000000002',
      );
      MockBleGatt.initForDevice(device);
    });

    tearDown(() {
      MockBleGatt.removeDevice(device);
    });

    test('readCharacteristic returns firmware UUID payloads', () {
      final deviceInfo = MockBleGatt.readCharacteristic(device, BleGattUuids.deviceInfo);
      expect(deviceInfo.first, 0x7B);

      final sensorInfo = MockBleGatt.readCharacteristic(device, BleGattUuids.sensorInfo);
      expect(sensorInfo.first, LDSensor.sen5x.id);

      final status = MockBleGatt.readCharacteristic(device, BleGattUuids.deviceStatus);
      expect(status, hasLength(5));
      expect(status[4], BleOperationalStatusFlags.configIncomplete);
    });

    test('aRound sensor_info includes SHTC3 block', () {
      final aRound = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-000000000003',
        bleMacAddress: '000000000003',
        deviceOriginalDisplayName: 'Mock aRound',
        isMock: true,
        bleId: 'mock:Luftdaten.at-000000000003',
      );
      MockBleGatt.initForDevice(aRound);

      final sensorInfo = MockBleGatt.readCharacteristic(aRound, BleGattUuids.sensorInfo);
      expect(sensorInfo, contains(LDSensor.shtc3.id));

      MockBleGatt.removeDevice(aRound);
    });

    test('command 0x01 refreshes sensor_values characteristic', () {
      final before = MockBleGattCodec.decodeSensorValuesBinary(
        MockBleGatt.readCharacteristic(device, BleGattUuids.sensorValues),
      );

      MockBleGatt.writeCommand(device, [MockBleGattCodec.cmdReadSensorData]);

      final after = MockBleGattCodec.decodeSensorValuesBinary(
        MockBleGatt.readCharacteristic(device, BleGattUuids.sensorValues),
      );

      expect(after, isNotEmpty);
      expect(after[MeasurableQuantity.pm25], isNotNull);
      expect(after[MeasurableQuantity.pm25], isNot(equals(before[MeasurableQuantity.pm25])));
    });

    test('command 0x06 merges air station configuration TLV', () {
      final writePayload = AirStationConfig(
        id: device.chipIdForApi,
        autoUpdateMode: AutoUpdateMode.on,
        batterySaverMode: BatterySaverMode.normal,
        measurementInterval: AirStationMeasurementInterval.min5,
        longitude: 16.37,
        latitude: 48.21,
        height: 171,
        deviceId: device.chipIdForApi,
        tz: 'Europe/Vienna',
      ).toBytes();

      MockBleGatt.writeCommand(device, writePayload);

      final readBack = MockBleGatt.readCharacteristic(
        device,
        BleGattUuids.airStationConfiguration,
      );
      final parsed = AirStationConfig.parseFromBytes(device.chipIdForApi, readBack);
      expect(parsed.longitude, closeTo(16.37, 0.001));
      expect(parsed.latitude, closeTo(48.21, 0.001));
      expect(parsed.tz, 'Europe/Vienna');
    });

    test('MockBleGattTransport routes reads and writes', () async {
      final transport = MockBleGattTransport.instance;
      final raw = await transport.readCharacteristic(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.deviceStatus,
      );
      expect(raw, hasLength(5));

      await transport.writeCharacteristicWithoutResponse(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.command,
        value: [MockBleGattCodec.cmdReadSensorDataAndBattery],
      );

      final sensorRaw = await transport.readCharacteristic(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.sensorValues,
      );
      expect(sensorRaw.length, greaterThan(2));
    });
  });
}
