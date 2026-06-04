import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';

import '../../../../test_helpers/mock_factories.dart';

void main() {
  late GetIt getIt;

  setUp(() {
    getIt = GetIt.instance;
    if (getIt.isRegistered<BatteryInfoAggregator>()) {
      getIt.unregister<BatteryInfoAggregator>();
    }
    getIt.registerSingleton<BatteryInfoAggregator>(
      MockFactories.createBatteryInfoAggregator(),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<BatteryInfoAggregator>()) {
      getIt.unregister<BatteryInfoAggregator>();
    }
  });

  group('BleDeviceStatusParser.parse', () {
    test('3-byte payload returns battery only, no notices', () {
      final r = BleDeviceStatusParser.parse([1, 50, 38]);
      expect(r.notices, isEmpty);
      expect(r.battery.status, BatteryStatus.discharging);
      expect(r.battery.percentage, 50.0);
    });

    test('CONFIG_INCOMPLETE only', () {
      final r = BleDeviceStatusParser.parse([1, 50, 38, 0, 0x01]);
      expect(r.notices.length, 1);
      expect(r.notices.first.id, 'config_incomplete');
      expect(r.notices.first.severity, BleNoticeSeverity.warning);
    });

    test('WIFI_FAILURE with credentials missing', () {
      final r = BleDeviceStatusParser.parse([1, 50, 38, 0x01, 0x02]);
      expect(r.notices.length, 1);
      expect(r.notices.first.id, 'wifi_credentials_missing');
    });

    test('WIFI_FAILURE with SSID not in scan', () {
      final r = BleDeviceStatusParser.parse([1, 50, 38, 0x02, 0x02]);
      expect(r.notices.single.id, 'wifi_ssid_not_found');
    });

    test('WIFI_FAILURE with connection failed', () {
      final r = BleDeviceStatusParser.parse([1, 50, 38, 0x03, 0x02]);
      expect(r.notices.single.id, 'wifi_connection_failed');
    });

    test('WIFI_FAILURE with ok detail uses generic message', () {
      final r = BleDeviceStatusParser.parse([1, 50, 38, 0, 0x02]);
      expect(r.notices.single.id, 'wifi_failure');
    });

    test('multiple flags produce multiple notices', () {
      final r = BleDeviceStatusParser.parse([1, 50, 38, 0x03, 0x03]);
      expect(r.notices.map((n) => n.id).toList(), [
        'config_incomplete',
        'wifi_connection_failed',
      ]);
    });

    test('NO_SENSOR flag', () {
      final r = BleDeviceStatusParser.parse([1, 50, 38, 0, 0x04]);
      expect(r.notices.single.id, 'no_sensor');
    });

    test('SSID_CONFIGURED alone produces no notices', () {
      final r = BleDeviceStatusParser.parse([1, 50, 38, 0, 0x08]);
      expect(r.notices, isEmpty);
    });
  });

  group('BleOperationalStatusFlags', () {
    test('parses combined bitmask', () {
      final f = BleOperationalStatusFlags.fromByte(0x07);
      expect(f.hasConfigIncomplete, isTrue);
      expect(f.hasWifiFailure, isTrue);
      expect(f.hasNoSensor, isTrue);
      expect(f.hasSsidConfigured, isFalse);
    });
  });
}
