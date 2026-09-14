import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/devices/data/sensor_calibration.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';
import 'package:luftdaten.at/features/devices/logic/device_calibration_store.dart';
import 'package:luftdaten.at/features/devices/logic/sensor_calibration_policy.dart';
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

  test('setOffset and getOffset round-trip', () {
    const bleName = 'Luftdaten.at-TEST00000001';
    store.setOffset(
      bleName,
      DeviceSensorOffset(
        sensor: LDSensor.scd4x,
        quantity: MeasurableQuantity.co2,
        offset: 35,
        calibratedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final offset = store.getOffset(bleName, LDSensor.scd4x, MeasurableQuantity.co2);
    expect(offset, isNotNull);
    expect(offset!.offset, 35);
  });

  test('offsets persist across reload', () async {
    const bleName = 'Luftdaten.at-TEST00000002';
    store.setOffset(
      bleName,
      DeviceSensorOffset(
        sensor: LDSensor.sen5x,
        quantity: MeasurableQuantity.temperature,
        offset: -1.5,
        calibratedAt: DateTime.utc(2026, 2, 1),
      ),
    );

    final reloaded = DeviceCalibrationStore();
    await reloaded.init();
    expect(
      reloaded.getOffset(bleName, LDSensor.sen5x, MeasurableQuantity.temperature)?.offset,
      -1.5,
    );
  });

  test('clearOffset removes entry', () {
    const bleName = 'Luftdaten.at-TEST00000003';
    store.setOffset(
      bleName,
      DeviceSensorOffset(
        sensor: LDSensor.bme280,
        quantity: MeasurableQuantity.humidity,
        offset: 2,
        calibratedAt: DateTime.utc(2026, 3, 1),
      ),
    );

    store.clearOffset(bleName, LDSensor.bme280, MeasurableQuantity.humidity);
    expect(store.offsetsForDevice(bleName), isEmpty);
  });

  group('SensorCalibrationPolicy', () {
    test('detects CO2, body heat, and climate offsets', () {
      final sensors = [
        SensorDetails(LDSensor.scd4x),
        SensorDetails(LDSensor.shtc3),
        SensorDetails(LDSensor.sen5x),
      ];

      expect(
        SensorCalibrationPolicy.capabilitiesFor(sensors),
        containsAll([
          CalibrationCapability.co2FreshAir,
          CalibrationCapability.bodyHeat,
          CalibrationCapability.temperatureOffset,
          CalibrationCapability.humidityOffset,
        ]),
      );
    });

    test('skips manual offsets for badge SHTC3', () {
      expect(
        SensorCalibrationPolicy.supportsQuantityOffset(
          LDSensor.shtc3,
          MeasurableQuantity.temperature,
        ),
        isFalse,
      );
      expect(
        SensorCalibrationPolicy.supportsQuantityOffset(
          LDSensor.shtc3,
          MeasurableQuantity.humidity,
        ),
        isFalse,
      );
    });

    test('returns empty capabilities without calibratable sensors', () {
      expect(
        SensorCalibrationPolicy.capabilitiesFor([SensorDetails(LDSensor.sds011)]),
        isEmpty,
      );
    });
  });
}
