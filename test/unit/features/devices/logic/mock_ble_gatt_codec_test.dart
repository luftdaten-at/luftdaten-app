import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt_codec.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  group('MockBleGattCodec', () {
    test('encodeSensorValuesBinary round-trips dimension values', () {
      final values = {
        MeasurableQuantity.pm25: 12.3,
        MeasurableQuantity.temperature: 21.7,
      };
      final encoded = MockBleGattCodec.encodeSensorValuesBinary(values);
      final decoded = MockBleGattCodec.decodeSensorValuesBinary(encoded);

      expect(decoded[MeasurableQuantity.pm25], closeTo(12.3, 0.05));
      expect(decoded[MeasurableQuantity.temperature], closeTo(21.7, 0.05));
    });

    test('encodeDeviceStatus sets config incomplete flag for stations', () {
      final bytes = MockBleGattCodec.encodeDeviceStatus(
        batteryPct: 80,
        operationalFlags: BleOperationalStatusFlags.configIncomplete,
      );
      expect(bytes, hasLength(5));
      expect(bytes[0], 1);
      expect(bytes[1], 80);
      expect(bytes[4], BleOperationalStatusFlags.configIncomplete);
    });

    test('encodeDeviceInfoJson starts with JSON brace', () {
      final device = BleDevice(
        model: LDDeviceModel.aRound,
        bleName: 'Luftdaten.at-000000000001',
        bleMacAddress: '000000000001',
        deviceOriginalDisplayName: 'Mock',
        isMock: true,
        bleId: 'mock:Luftdaten.at-000000000001',
      );
      final bytes = MockBleGattCodec.encodeDeviceInfoJson(device);
      expect(bytes.first, 0x7B);
    });

    test('mergeTlvRecords overwrites same flag', () {
      final base = <int>[0, 4, 0, 0, 0, 1];
      final incoming = <int>[0, 4, 0, 0, 0, 2];
      final merged = MockBleGattCodec.mergeTlvRecords(base, incoming);
      expect(merged, hasLength(6));
      expect(merged.last, 2);
    });

    test('encodeAirStationConfigReadBack excludes Wi-Fi secrets', () {
      final config = AirStationConfig(
        id: 'TESTAAA',
        autoUpdateMode: AutoUpdateMode.on,
        batterySaverMode: BatterySaverMode.normal,
        measurementInterval: AirStationMeasurementInterval.min5,
        longitude: 16.3,
        latitude: 48.2,
        height: 200,
        deviceId: 'TESTAAA',
        tz: 'Europe/Vienna',
      );
      final tlv = MockBleGattCodec.encodeAirStationConfigReadBack(config);
      final parsed = AirStationConfig.parseFromBytes('TESTAAA', tlv);
      expect(parsed.tz, 'Europe/Vienna');
      expect(parsed.longitude, closeTo(16.3, 0.001));
    });
  });
}
