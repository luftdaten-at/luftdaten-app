import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_firmware_image.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/ble_ota.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';

void main() {
  group('MockBleGatt OTA', () {
    late BleDevice device;

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
    });

    tearDown(() {
      MockBleGatt.removeDevice(device);
    });

    test('ota_control read returns idle status frame', () {
      final raw = MockBleGatt.readCharacteristic(device, BleGattUuids.otaControl);
      expect(raw, hasLength(8));
      expect(raw.first, BleOtaState.idle);
    });

    test('full OTA updates firmware version on finish', () async {
      final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i & 0xff));
      final target = const FirmwareVersion(1, 1, 0);
      final image = BadgeFirmwareImage(bytes: bytes, targetVersion: target);
      final transport = MockBleGattTransport.instance;

      final notifySub = transport
          .subscribeCharacteristic(
            deviceId: device.bleId!,
            serviceId: BleGattUuids.service,
            characteristicId: BleGattUuids.otaControl,
          )
          .listen((_) {});

      await transport.writeCharacteristicWithResponse(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.otaControl,
        value: buildBleOtaStartPayload(image: image),
      );

      var offset = 0;
      while (offset < bytes.length) {
        final end = offset + 20 > bytes.length ? bytes.length : offset + 20;
        await transport.writeCharacteristicWithoutResponse(
          deviceId: device.bleId!,
          serviceId: BleGattUuids.service,
          characteristicId: BleGattUuids.otaData,
          value: bytes.sublist(offset, end),
        );
        offset = end;
      }

      await transport.writeCharacteristicWithResponse(
        deviceId: device.bleId!,
        serviceId: BleGattUuids.service,
        characteristicId: BleGattUuids.otaControl,
        value: const [BleOtaCommand.finish],
      );

      await notifySub.cancel();
      expect(device.firmwareVersion?.major, target.major);
      expect(device.firmwareVersion?.minor, target.minor);
      expect(device.firmwareVersion?.patch, target.patch);
      expect(sha256.convert(bytes).bytes, image.sha256Digest);
    });
  });
}
