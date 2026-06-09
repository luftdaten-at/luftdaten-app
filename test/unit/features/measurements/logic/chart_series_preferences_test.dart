import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/measurements/logic/chart_series_preferences.dart';

void main() {
  late ChartSeriesPreferences prefs;

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
    GetStorage('settings').remove('chartSeriesVisibility');
    prefs = ChartSeriesPreferences()..init();
  });

  test('particulate PM4 defaults to hidden', () {
    expect(
      prefs.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm4),
      isFalse,
    );
    expect(
      prefs.isVisible(ChartSeriesChartId.particulate, ChartSeriesKeys.pm25),
      isTrue,
    );
  });

  test('unknown series defaults to visible', () {
    expect(
      prefs.isVisible(ChartSeriesChartId.temperature, 'sen5x'),
      isTrue,
    );
  });

  test('setVisible and isVisible round-trip', () {
    prefs.setVisible(ChartSeriesChartId.temperature, 'sen5x', false);
    expect(
      prefs.isVisible(ChartSeriesChartId.temperature, 'sen5x'),
      isFalse,
    );
    expect(
      prefs.isVisible(ChartSeriesChartId.temperature, 'bme280'),
      isTrue,
    );
  });

  test('setAll replaces chart visibility map', () {
    prefs.setAll(ChartSeriesChartId.particulate, {
      ChartSeriesKeys.pm1: false,
      ChartSeriesKeys.pm25: true,
    });
    expect(prefs.visibilityFor(ChartSeriesChartId.particulate), {
      ChartSeriesKeys.pm1: false,
      ChartSeriesKeys.pm25: true,
    });
  });

  test('preferences persist across reload', () {
    prefs.setVisible(ChartSeriesChartId.nox, ChartSeriesKeys.mean, false);

    final reloaded = ChartSeriesPreferences()..init();
    expect(
      reloaded.isVisible(ChartSeriesChartId.nox, ChartSeriesKeys.mean),
      isFalse,
    );
  });
}
