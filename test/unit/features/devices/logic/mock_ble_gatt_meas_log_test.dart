import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_meas_log_export.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt_codec.dart';

void main() {
  group('MockBleGatt measurement log', () {
    late BleDevice device;
    late MockBleGattTransport transport;

    setUp(() {
      device = BleDevice(
        model: LDDeviceModel.badge,
        bleName: 'Luftdaten.at-000000000010',
        bleMacAddress: '000000000010',
        deviceOriginalDisplayName: 'Mock Badge',
        isMock: true,
        bleId: 'mock:Luftdaten.at-000000000010',
      )..firmwareVersion = const FirmwareVersion(1, 0, 0);
      MockBleGatt.initForDevice(device);
      transport = MockBleGattTransport.instance;
    });

    tearDown(() {
      MockBleGatt.removeDevice(device);
    });

    test('LOG_STATUS read returns non-empty log metadata', () async {
      await transport.writeCharacteristicWithResponse(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.logControl,
        value: const [BadgeMeasLogCommand.logStatus],
      );
      final raw = await transport.readCharacteristic(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.logControl,
      );
      final frame = BadgeMeasLogStatusFrame.parse(raw);
      expect(frame, isNotNull);
      expect(frame!.hasRecords, isTrue);
      expect(frame.recordCount, 2);
    });

    test('START_EXPORT delivers full LDLG blob with DONE notify', () async {
      final expected = MockBleGattCodec.encodeBadgeMeasLogBlob();
      final buffer = <int>[];
      BadgeMeasLogStatusFrame? doneFrame;

      final controlSub = transport
          .subscribeCharacteristic(
            deviceId: device.bleId!,
            serviceId: BleGattUuids.service,
            characteristicId: BleGattUuids.logControl,
          )
          .listen((raw) {
        final frame = BadgeMeasLogStatusFrame.parse(raw);
        if (frame?.state == BadgeMeasLogState.done) doneFrame = frame;
      });

      final dataSub = transport
          .subscribeCharacteristic(
            deviceId: device.bleId!,
            serviceId: BleGattUuids.service,
            characteristicId: BleGattUuids.logData,
          )
          .listen((raw) {
        if (raw.length > 2) buffer.addAll(raw.sublist(2));
      });

      await transport.writeCharacteristicWithResponse(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.logControl,
        value: const [BadgeMeasLogCommand.startExport],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await controlSub.cancel();
      await dataSub.cancel();
      MockBleGatt.closeMeasLogSubscriptions(device);

      expect(buffer.length, expected.length);
      expect(doneFrame, isNotNull);
      expect(doneFrame!.offset, expected.length);
    });

    test('LOG_ERASE clears log', () async {
      await transport.writeCharacteristicWithResponse(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.logControl,
        value: const [BadgeMeasLogCommand.logErase],
      );
      final raw = await transport.readCharacteristic(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.logControl,
      );
      final frame = BadgeMeasLogStatusFrame.parse(raw);
      expect(frame?.hasRecords ?? true, isFalse);
    });

    test('log_data chunks include seq prefix', () async {
      final dataChunks = <List<int>>[];
      final sub = transport
          .subscribeCharacteristic(
            deviceId: device.bleId!,
            serviceId: BleGattUuids.service,
            characteristicId: BleGattUuids.logData,
          )
          .listen(dataChunks.add);

      await transport.writeCharacteristicWithResponse(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.logControl,
        value: const [BadgeMeasLogCommand.startExport],
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      MockBleGatt.closeMeasLogSubscriptions(device);

      expect(dataChunks, isNotEmpty);
      for (final chunk in dataChunks) {
        expect(chunk.length, greaterThan(2));
      }
    });
  });
}
