import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';

void main() {
  AirStationConfig baseConfig() => AirStationConfig(
        id: 'station-1',
        autoUpdateMode: AutoUpdateMode.on,
        batterySaverMode: BatterySaverMode.normal,
        measurementInterval: AirStationMeasurementInterval.min5,
        longitude: 16.37,
        latitude: 48.21,
        height: 180.0,
        deviceId: 'device-123',
        tz: 'Europe/Vienna',
        mqttEnabled: true,
        mqttBroker: 'mqtt.example.com',
        mqttPort: 8883,
        mqttUseTls: true,
      );

  test('nonSecretFieldsEqual returns true for identical configs', () {
    final a = baseConfig();
    final b = baseConfig();
    expect(a.nonSecretFieldsEqual(b), isTrue);
  });

  test('nonSecretFieldsEqual returns false when measurement interval differs', () {
    final a = baseConfig();
    final b = baseConfig()..measurementInterval = AirStationMeasurementInterval.min10;
    expect(a.nonSecretFieldsEqual(b), isFalse);
  });

  test('parseFromBytes matches toBytes for core TLV fields', () {
    final original = baseConfig();
    final bytes = original.toBytes();
    final parsed = AirStationConfig.parseFromBytes('station-1', bytes);

    expect(parsed.measurementInterval, original.measurementInterval);
    expect(parsed.longitude, original.longitude);
    expect(parsed.latitude, original.latitude);
    expect(parsed.deviceId, isNull);
    expect(original.nonSecretFieldsEqual(parsed), isFalse);
    expect(parsed.tz, original.tz);
  });
}
