import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_telemetry.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

void main() {
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
    await GetStorage.init('settings');
    GetIt.instance.reset();
    getIt.registerSingleton<DeviceManager>(DeviceManager());
    getIt.registerSingleton<BatteryInfoAggregator>(BatteryInfoAggregator());
    AppSettings.I.mockBleDevicesEnabled = true;
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  test('readSensorValues returns sensor points and metadata', () {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );

    final result = MockBleTelemetry.readSensorValues(device);
    expect(result.length, 2);

    final points = result[0] as List<SensorDataPoint>;
    expect(points, isNotEmpty);
    expect(points.first.values[MeasurableQuantity.pm25], isNotNull);

    final metadata = result[1] as Map<String, dynamic>;
    expect(metadata['mock'], isTrue);
    expect(metadata['chip_id'], device.chipIdForApi);
  });
}
