import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/logic/ble_sensor_values_binary.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') return '/tmp';
      if (methodCall.method == 'getTemporaryDirectory') return '/tmp';
      return null;
    });
    await GetStorage.init('AppSettings');
  });

  group('parseBleSensorValuesBinary', () {
    test('decodes BMV080 PM triple from firmware example', () {
      const bytes = <int>[
        0x1F,
        0x03,
        0x02,
        0x00,
        0x54,
        0x03,
        0x00,
        0x7B,
        0x05,
        0x00,
        0x96,
      ];

      final readings = parseBleSensorValuesBinary(bytes);

      expect(readings, hasLength(1));
      expect(readings.single.sensor, LDSensor.bmv080);
      expect(readings.single.values[MeasurableQuantity.pm1], closeTo(8.4, 0.05));
      expect(readings.single.values[MeasurableQuantity.pm25], closeTo(12.3, 0.05));
      expect(readings.single.values[MeasurableQuantity.pm10], closeTo(15.0, 0.05));
    });

    test('omits dimension when raw value is 0x0000', () {
      const bytes = <int>[
        0x1F,
        0x02,
        0x02,
        0x00,
        0x00,
        0x03,
        0x00,
        0x7B,
      ];

      final readings = parseBleSensorValuesBinary(bytes);

      expect(readings.single.values.containsKey(MeasurableQuantity.pm1), isFalse);
      expect(readings.single.values[MeasurableQuantity.pm25], closeTo(12.3, 0.05));
    });
  });
}
