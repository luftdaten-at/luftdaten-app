import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/data/sensor_calibration.dart';
import 'package:luftdaten.at/features/devices/logic/apply_sensor_calibration.dart';
import 'package:luftdaten.at/features/devices/logic/device_calibration_store.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
  late DeviceCalibrationStore store;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') return '/tmp';
      if (methodCall.method == 'getTemporaryDirectory') return '/tmp';
      return null;
    });
  });

  setUp(() async {
    await GetStorage.init('deviceCalibration');
    GetStorage('deviceCalibration').erase();
    store = DeviceCalibrationStore();
    await store.init();
  });

  test('applySensorCalibration adds stored offset to matching quantity', () {
    const bleName = 'Luftdaten.at-APPLYTEST01';
    store.setOffset(
      bleName,
      DeviceSensorOffset(
        sensor: LDSensor.scd4x,
        quantity: MeasurableQuantity.co2,
        offset: 40,
        calibratedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final point = SensorDataPoint(
      sensor: LDSensor.scd4x,
      values: {MeasurableQuantity.co2: 800},
    );

    final corrected = applySensorCalibration(bleName, point, store: store);
    expect(corrected.values[MeasurableQuantity.co2], 840);
  });

  test('applySensorCalibration ignores offsets for other sensors', () {
    const bleName = 'Luftdaten.at-APPLYTEST02';
    store.setOffset(
      bleName,
      DeviceSensorOffset(
        sensor: LDSensor.scd4x,
        quantity: MeasurableQuantity.co2,
        offset: 40,
        calibratedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final point = SensorDataPoint(
      sensor: LDSensor.sen5x,
      values: {MeasurableQuantity.co2: 800},
    );

    final corrected = applySensorCalibration(bleName, point, store: store);
    expect(corrected.values[MeasurableQuantity.co2], 800);
  });

  test('applySensorCalibrationToReadResult handles tuple read results', () {
    const bleName = 'Luftdaten.at-APPLYTEST03';
    store.setOffset(
      bleName,
      DeviceSensorOffset(
        sensor: LDSensor.sen5x,
        quantity: MeasurableQuantity.temperature,
        offset: -0.8,
        calibratedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final result = applySensorCalibrationToReadResult(
      bleName,
      [
        [
          SensorDataPoint(
            sensor: LDSensor.sen5x,
            values: {MeasurableQuantity.temperature: 21.0},
          ),
        ],
        {'chip_id': 'abcd'},
      ],
      store: store,
    );

    final points = result.first as List<SensorDataPoint>;
    expect(points.first.values[MeasurableQuantity.temperature], closeTo(20.2, 0.001));
    expect(result[1], {'chip_id': 'abcd'});
  });
}
