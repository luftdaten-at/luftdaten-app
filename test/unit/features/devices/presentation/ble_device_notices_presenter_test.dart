import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/ble_device_notices_presenter.dart';

void main() {
  group('BleDeviceNoticesPresenter', () {
    test('showAfterConnectIfNeeded does nothing when notices empty', () {
      final device = BleDevice(
        model: LDDeviceModel.station,
        bleName: 'Luftdaten.at-Test',
        bleMacAddress: 'AABBCCDDEEFF',
        deviceOriginalDisplayName: 'Test Station',
      );
      expect(() => BleDeviceNoticesPresenter.showAfterConnectIfNeeded(device), returnsNormally);
    });

    test('buildNoticesDialogContent lists notice messages', () {
      const notices = [
        BleDeviceNotice(id: 'wifi_failure', severity: BleNoticeSeverity.error),
        BleDeviceNotice(id: 'config_incomplete', severity: BleNoticeSeverity.warning),
      ];
      final widget = BleDeviceNoticesPresenter.buildNoticesDialogContent(
        notices,
        deviceDisplayName: 'Air Station 0001',
      );

      expect(widget, isA<Column>());
    });

    test('buildNoticesDialogContent includes device name and one notice row', () {
      const notices = [
        BleDeviceNotice(id: 'no_sensor', severity: BleNoticeSeverity.error),
      ];
      final column = BleDeviceNoticesPresenter.buildNoticesDialogContent(
        notices,
        deviceDisplayName: 'My Device',
      ) as Column;

      expect(column.children.length, 2);
    });
  });
}
