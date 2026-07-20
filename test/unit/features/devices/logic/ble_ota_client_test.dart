import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_firmware_image.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/ble_gatt_transport.dart';
import 'package:luftdaten.at/features/devices/logic/ble_ota.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

class _SingleSubscriptionOtaTransport implements BleGattTransport {
  _SingleSubscriptionOtaTransport({
    required Stream<List<int>> notifyStream,
    required void Function(List<int> value) onOtaControlWrite,
  })  : _notifyStream = notifyStream,
        _onOtaControlWrite = onOtaControlWrite;

  final Stream<List<int>> _notifyStream;
  final void Function(List<int> value) _onOtaControlWrite;

  @override
  Future<int> requestMtu({required String deviceId, required int mtu}) async => 517;

  @override
  Stream<List<int>> subscribeCharacteristic({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
  }) =>
      _notifyStream;

  @override
  Future<void> writeCharacteristicWithResponse({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
    required List<int> value,
  }) async {
    if (characteristicId == BleGattUuids.otaControl) {
      _onOtaControlWrite(value);
    }
  }

  @override
  Future<void> writeCharacteristicWithoutResponse({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
    required List<int> value,
  }) async {}

  @override
  Future<List<int>> readCharacteristic({
    required String deviceId,
    required Uuid serviceId,
    required Uuid characteristicId,
  }) async =>
      BleOtaStatusFrame.encode(state: BleOtaState.idle);
}

void main() {
  setUpAll(initDeviceWidgetTestHarness);

  group('BleOtaClient single-subscription notify stream', () {
    setUp(() async {
      await setUpDeviceWidgetTests(
        storageBucket: 'ble_ota_client_single_sub_tests',
        mockBleEnabled: false,
      );
    });

    tearDown(tearDownDeviceWidgetTests);

    test('performUpdate does not double-listen on START phase', () async {
      final controller = StreamController<List<int>>();
      final transport = _SingleSubscriptionOtaTransport(
        notifyStream: controller.stream,
        onOtaControlWrite: (value) {
          if (value.isNotEmpty && value.first == BleOtaCommand.start) {
            controller.add(BleOtaStatusFrame.encode(state: BleOtaState.ready));
          }
        },
      );

      final device = BleDevice(
        model: LDDeviceModel.badge,
        bleName: 'Luftdaten.at-000000000099',
        bleMacAddress: '000000000099',
        deviceOriginalDisplayName: 'Test Badge',
        bleId: 'test-badge-ota',
      )
        ..state = BleDeviceState.connected
        ..firmwareVersion = const FirmwareVersion(1, 0, 0);

      final image = BadgeFirmwareImage(
        bytes: Uint8List(64),
        targetVersion: const FirmwareVersion(1, 1, 0),
      );

      var startPhasePassed = false;
      final result = await BleOtaClient(
        transport: transport,
        bleController: BleController(),
      ).performUpdate(
        device: device,
        image: image,
        shouldCancel: () async {
          startPhasePassed = true;
          return true;
        },
      );

      expect(startPhasePassed, isTrue);
      expect(result.cancelled, isTrue);
      expect(result.errorMessage, isNot(contains('Stream has already been listened to')));
      await controller.close();
    });
  });

  group('BleOtaClient with mock GATT', () {
    setUp(() async {
      await setUpDeviceWidgetTests(
        storageBucket: 'ble_ota_client_tests',
        mockBleEnabled: true,
      );
    });

    tearDown(tearDownDeviceWidgetTests);

    test('performUpdate completes and updates firmware version', () async {
      final device = MockBleDevices.buildMockDevice(
        LDDeviceModel.badge,
        existingBleNames: const [],
      )
        ..state = BleDeviceState.connected
        ..firmwareVersion = const FirmwareVersion(1, 0, 0);
      MockBleGatt.initForDevice(device);

      final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i & 0xff));
      final image = BadgeFirmwareImage(
        bytes: bytes,
        targetVersion: const FirmwareVersion(1, 1, 0),
      );

      final result = await BleOtaClient(
        transport: MockBleGattTransport.instance,
        bleController: BleController(),
      ).performUpdate(device: device, image: image);

      expect(result.ok, isTrue, reason: result.errorMessage);
      expect(result.confirmedVersion.toString(), '1.1.0');
      expect(device.firmwareVersion.toString(), '1.1.0');

      MockBleGatt.removeDevice(device);
    });
  });
}
