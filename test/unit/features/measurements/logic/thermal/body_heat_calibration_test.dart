import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/body_heat_calibration.dart';

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
    await GetStorage.init('bodyHeatCalibration');
    GetStorage('bodyHeatCalibration').erase();
  });

  test('requires 30 samples for calibrated median', () {
    final store = BodyHeatCalibrationStore();
    final now = DateTime(2026, 7, 1, 12);

    for (var i = 0; i < 29; i++) {
      store.maybeRecord(
        timestamp: now.subtract(Duration(minutes: i * 30)),
        tBadgeC: 22,
        t2mApiC: 20,
        lux: 1,
        v10Ms: 2,
        previousTBadgeC: null,
        previousTimestamp: null,
        isOutdoor: true,
      );
    }

    expect(store.delta(now: now).isCalibrated, isFalse);
    expect(store.delta(now: now).usingFallback, isFalse);

    store.maybeRecord(
      timestamp: now.subtract(const Duration(minutes: 29 * 30)),
      tBadgeC: 22,
      t2mApiC: 20,
      lux: 1,
      v10Ms: 2,
      previousTBadgeC: null,
      previousTimestamp: null,
      isOutdoor: true,
    );

    final result = store.delta(now: now);
    expect(result.isCalibrated, isTrue);
    expect(result.deltaK, closeTo(2.0, 0.01));
  });

  test('rejects samples when gates fail', () {
    final store = BodyHeatCalibrationStore();
    final now = DateTime(2026, 7, 1, 12);

    store.maybeRecord(
      timestamp: now,
      tBadgeC: 22,
      t2mApiC: 20,
      lux: 100,
      v10Ms: 2,
      previousTBadgeC: null,
      previousTimestamp: null,
      isOutdoor: true,
    );

    expect(store.delta(now: now).sampleCount, 0);
  });
}
