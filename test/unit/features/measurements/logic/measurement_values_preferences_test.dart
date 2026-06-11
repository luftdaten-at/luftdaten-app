import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_display_defaults.dart';
import 'package:luftdaten.at/features/measurements/logic/measurement_values_preferences.dart';

void main() {
  late MeasurementValuesPreferences prefs;

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
    GetStorage('settings').remove('measurementValuesVisibility');
    prefs = MeasurementValuesPreferences()..init();
  });

  final dualSensors = {LDSensor.sen5x, LDSensor.shtc3};
  const sen5xTempKey = 'sen5x:temperature';
  const sen5xHumidityKey = 'sen5x:humidity';
  const shtc3TempKey = 'shtc3:temperature';

  test('sen5x temperature and humidity default hidden with secondary sensor', () {
    expect(
      prefs.isVisible(sen5xTempKey, tripSensors: dualSensors),
      isFalse,
    );
    expect(
      prefs.isVisible(sen5xHumidityKey, tripSensors: dualSensors),
      isFalse,
    );
    expect(
      prefs.isVisible(shtc3TempKey, tripSensors: dualSensors),
      isTrue,
    );
  });

  test('sen5x climate values visible on single-sensor trip', () {
    expect(
      prefs.isVisible(sen5xTempKey, tripSensors: {LDSensor.sen5x}),
      isTrue,
    );
  });

  test('stored override wins over dual-sensor default', () {
    prefs.setVisible(sen5xTempKey, true);
    expect(
      prefs.isVisible(sen5xTempKey, tripSensors: dualSensors),
      isTrue,
    );
  });

  test('preferences persist across reload', () {
    prefs.setVisible(sen5xHumidityKey, false);

    final reloaded = MeasurementValuesPreferences()..init();
    expect(
      reloaded.isVisible(
        sen5xHumidityKey,
        tripSensors: dualSensors,
        defaultValue: true,
      ),
      isFalse,
    );
  });

  test('MeasurementDisplayDefaults seriesKey format', () {
    expect(
      MeasurementDisplayDefaults.seriesKey(
        LDSensor.sen5x,
        MeasurableQuantity.temperature,
      ),
      sen5xTempKey,
    );
  });
}
