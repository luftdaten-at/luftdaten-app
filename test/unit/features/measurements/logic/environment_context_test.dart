import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/environment_context.dart';

final _start = DateTime(2026, 1, 1, 12);

MeasuredDataPoint _point({
  required DateTime timestamp,
  double? lux,
  double? uva,
  double? uvb,
  double? uvc,
  double? visible,
  double? infrared,
  double? fullSpectrum,
  double? temperature,
}) {
  return MeasuredDataPoint(
    timestamp: timestamp,
    sensorData: [
      SensorDataPoint(
        sensor: LDSensor.tsl2591,
        values: {
          if (lux != null) MeasurableQuantity.lux: lux,
          if (visible != null) MeasurableQuantity.visible: visible,
          if (infrared != null) MeasurableQuantity.infrared: infrared,
          if (fullSpectrum != null) MeasurableQuantity.fullSpectrum: fullSpectrum,
        },
      ),
      SensorDataPoint(
        sensor: LDSensor.as7331,
        values: {
          if (uva != null) MeasurableQuantity.uva: uva,
          if (uvb != null) MeasurableQuantity.uvb: uvb,
          if (uvc != null) MeasurableQuantity.uvc: uvc,
        },
      ),
      SensorDataPoint(
        sensor: LDSensor.shtc3,
        values: {
          if (temperature != null) MeasurableQuantity.temperature: temperature,
        },
      ),
    ],
  );
}

/// Repeat one signature [count] times at a fixed sampling interval.
List<MeasuredDataPoint> _history({
  required int count,
  Duration interval = const Duration(seconds: 30),
  double? lux,
  double? uva,
  double? uvb,
  double? infrared,
  double? fullSpectrum,
  double? Function(int index)? temperature,
}) {
  return [
    for (var i = 0; i < count; i++)
      _point(
        timestamp: _start.add(interval * i),
        lux: lux,
        uva: uva,
        uvb: uvb,
        infrared: infrared,
        fullSpectrum: fullSpectrum,
        temperature: temperature?.call(i),
      ),
  ];
}

MeasuredDataPoint _shift(MeasuredDataPoint point, Duration offset) {
  return MeasuredDataPoint(
    timestamp: point.timestamp.add(offset),
    sensorData: point.sensorData,
  );
}

/// Signatures from the expected-values table of the design document.
EnvironmentContextFeatures _signature({
  required double lux,
  required double rIr,
  required double kUv,
  required double beta,
  bool saturated = false,
}) {
  final uva = kUv * lux;
  return EnvironmentContextFeatures(
    lux: lux,
    uva: uva,
    uvb: beta * uva,
    rIr: rIr,
    saturated: saturated,
  );
}

void main() {
  group('ramp', () {
    test('clamps to the interval bounds', () {
      expect(EnvironmentContextClassifier.ramp(0, 1, 2), -1);
      expect(EnvironmentContextClassifier.ramp(5, 1, 2), 1);
    });

    test('is zero at the midpoint', () {
      expect(EnvironmentContextClassifier.ramp(1.5, 1, 2), closeTo(0, 1e-9));
    });
  });

  group('scoreOf', () {
    test('direct sun scores fully outdoor', () {
      final score = EnvironmentContextClassifier.scoreOf(
        _signature(lux: 90000, rIr: 0.40, kUv: 0.045, beta: 0.035, saturated: true),
      );
      expect(score, closeTo(1, 1e-9));
    });

    test('overcast outdoor scores outdoor', () {
      final score = EnvironmentContextClassifier.scoreOf(
        _signature(lux: 10000, rIr: 0.36, kUv: 0.07, beta: 0.03),
      );
      expect(score, greaterThan(EnvironmentContextClassifier.switchThreshold));
    });

    test('outdoor shade still scores outdoor', () {
      final score = EnvironmentContextClassifier.scoreOf(
        _signature(lux: 4000, rIr: 0.34, kUv: 0.09, beta: 0.03),
      );
      expect(score, greaterThan(EnvironmentContextClassifier.switchThreshold));
    });

    test('LED room lighting scores indoor', () {
      final score = EnvironmentContextClassifier.scoreOf(
        _signature(lux: 400, rIr: 0.14, kUv: 0.0003, beta: 0),
      );
      expect(score, lessThan(-EnvironmentContextClassifier.switchThreshold));
    });

    test('fluorescent lighting scores indoor', () {
      final score = EnvironmentContextClassifier.scoreOf(
        _signature(lux: 600, rIr: 0.20, kUv: 0.002, beta: 0.0008),
      );
      expect(score, lessThan(-EnvironmentContextClassifier.switchThreshold));
    });

    test('halogen lighting scores indoor despite its high IR share', () {
      final score = EnvironmentContextClassifier.scoreOf(
        _signature(lux: 200, rIr: 0.65, kUv: 0.0005, beta: 0),
      );
      expect(score, lessThan(-EnvironmentContextClassifier.switchThreshold));
    });

    test('IR share is a two-sided test, so an excessive share lowers the score', () {
      final daylight = EnvironmentContextClassifier.scoreOf(
        _signature(lux: 5000, rIr: 0.36, kUv: 0.07, beta: 0.03),
      );
      final tooMuchIr = EnvironmentContextClassifier.scoreOf(
        _signature(lux: 5000, rIr: 0.65, kUv: 0.07, beta: 0.03),
      );
      expect(daylight, greaterThan(0.99));
      expect(tooMuchIr, lessThan(daylight));
    });

    test('stays neutral without any usable signal', () {
      const features = EnvironmentContextFeatures(lux: 0.5, uva: 0.01);
      expect(EnvironmentContextClassifier.scoreOf(features), 0);
    });

    test('masks out the UVB test below the UVA noise floor', () {
      // UVB/UVA is meaningless once UVA is just noise, so the test is dropped
      // rather than counted as evidence either way.
      const withoutUvb = EnvironmentContextFeatures(lux: 500, uva: 0.01, uvb: 0, rIr: 0.35);
      const withUvb = EnvironmentContextFeatures(lux: 500, uva: 0.01, uvb: 5, rIr: 0.35);
      expect(
        EnvironmentContextClassifier.scoreOf(withoutUvb),
        EnvironmentContextClassifier.scoreOf(withUvb),
      );
      // Above the noise floor the same difference does move the score.
      const litWithoutUvb = EnvironmentContextFeatures(lux: 500, uva: 1, uvb: 0, rIr: 0.35);
      const litWithUvb = EnvironmentContextFeatures(lux: 500, uva: 1, uvb: 0.5, rIr: 0.35);
      expect(
        EnvironmentContextClassifier.scoreOf(litWithUvb),
        greaterThan(EnvironmentContextClassifier.scoreOf(litWithoutUvb)),
      );
    });
  });

  group('features', () {
    test('window signature needs UVA, missing UVB and enough light', () {
      expect(
        _signature(lux: 1000, rIr: 0.38, kUv: 0.01, beta: 0.003).isWindowSignature,
        isTrue,
      );
      // Same light level, but UVB present: open sky.
      expect(
        _signature(lux: 1000, rIr: 0.38, kUv: 0.01, beta: 0.03).isWindowSignature,
        isFalse,
      );
      // Too dark to tell.
      expect(
        _signature(lux: 150, rIr: 0.38, kUv: 0.01, beta: 0.003).isWindowSignature,
        isFalse,
      );
    });

    test('darkness is detected from illuminance and UVA together', () {
      expect(
        const EnvironmentContextFeatures(lux: 2, uva: 0.01).isDark,
        isTrue,
      );
      expect(
        const EnvironmentContextFeatures(lux: 2, uva: 5).isDark,
        isFalse,
      );
      expect(
        const EnvironmentContextFeatures(lux: 200, uva: 0.01).isDark,
        isFalse,
      );
    });

    test('flags UVC, which cannot occur outdoors', () {
      expect(
        const EnvironmentContextFeatures(lux: 500, uvc: 1.2).hasUvcAnomaly,
        isTrue,
      );
      expect(
        const EnvironmentContextFeatures(lux: 500, uvc: 0).hasUvcAnomaly,
        isFalse,
      );
    });

    test('derives the IR share from full spectrum when available', () {
      final features = EnvironmentContextClassifier.featuresAt(
        _point(
          timestamp: _start,
          lux: 500,
          uva: 1,
          infrared: 400,
          fullSpectrum: 1000,
          visible: 600,
        ),
      );
      expect(features!.rIr, closeTo(0.4, 1e-9));
    });

    test('falls back to visible + infrared for the IR share', () {
      final features = EnvironmentContextClassifier.featuresAt(
        _point(timestamp: _start, lux: 500, uva: 1, infrared: 400, visible: 600),
      );
      expect(features!.rIr, closeTo(0.4, 1e-9));
    });

    test('flags saturation from the channel ceiling and the lux limit', () {
      final byChannel = EnvironmentContextClassifier.featuresAt(
        _point(timestamp: _start, lux: 500, uva: 1, fullSpectrum: 65535),
      );
      final byLux = EnvironmentContextClassifier.featuresAt(
        _point(timestamp: _start, lux: 95000, uva: 1),
      );
      expect(byChannel!.saturated, isTrue);
      expect(byLux!.saturated, isTrue);
    });

    test('returns null without light and UV data', () {
      final features = EnvironmentContextClassifier.featuresAt(
        _point(timestamp: _start, temperature: 21),
      );
      expect(features, isNull);
    });
  });

  group('analyze', () {
    test('needs 90 s of matching evidence before leaving the initial state', () {
      final analysis = EnvironmentContextClassifier.analyze(
        history: _history(count: 5, lux: 10000, uva: 700, uvb: 21, infrared: 3600, fullSpectrum: 10000),
      );

      // Samples at 0/30/60/90/120 s: the 90 s mark is the first switch point.
      expect(
        analysis.samples.map((e) => e.state),
        [
          EnvironmentContextState.unknown,
          EnvironmentContextState.unknown,
          EnvironmentContextState.unknown,
          EnvironmentContextState.outdoor,
          EnvironmentContextState.outdoor,
        ],
      );
    });

    test('an established state switches after exactly three cycles', () {
      final outdoor = _history(
        count: 10,
        lux: 10000,
        uva: 700,
        uvb: 21,
        infrared: 3600,
        fullSpectrum: 10000,
      );
      final indoor = _history(
        count: 4,
        lux: 400,
        uva: 0.12,
        uvb: 0,
        infrared: 56,
        fullSpectrum: 400,
      ).map((e) => _shift(e, const Duration(minutes: 5))).toList();

      final analysis = EnvironmentContextClassifier.analyze(
        history: [...outdoor, ...indoor],
      );
      final states = analysis.samples.map((e) => e.state).toList();

      expect(states[9], EnvironmentContextState.outdoor);
      expect(states[10], EnvironmentContextState.outdoor);
      expect(states[11], EnvironmentContextState.outdoor);
      expect(states[12], EnvironmentContextState.indoor);
    });

    test('a faster sampling interval does not shorten the hysteresis', () {
      final fast = _history(
        count: 10,
        interval: const Duration(seconds: 10),
        lux: 10000,
        uva: 700,
        uvb: 21,
        infrared: 3600,
        fullSpectrum: 10000,
      );
      final analysis = EnvironmentContextClassifier.analyze(history: fast);

      // 90 s of evidence at 10 s sampling is 9 cycles, not 3.
      expect(analysis.samples[8].state, EnvironmentContextState.unknown);
      expect(analysis.samples.last.state, EnvironmentContextState.outdoor);
    });

    test('classifies a window seat and reports it with full confidence', () {
      final analysis = EnvironmentContextClassifier.analyze(
        history: _history(count: 5, lux: 1000, uva: 10, uvb: 0.03, infrared: 380, fullSpectrum: 1000),
      );

      final latest = analysis.latest!;
      expect(latest.state, EnvironmentContextState.indoorWindow);
      expect(latest.score, 0);
      expect(latest.confidence, 1);
    });

    test('reports LED room lighting as indoor', () {
      final analysis = EnvironmentContextClassifier.analyze(
        history: _history(count: 5, lux: 400, uva: 0.12, uvb: 0, infrared: 56, fullSpectrum: 400),
      );

      final latest = analysis.latest!;
      expect(latest.state, EnvironmentContextState.indoor);
      expect(latest.confidence, greaterThan(0.4));
    });

    test('holds unknown in darkness instead of assuming indoor', () {
      final analysis = EnvironmentContextClassifier.analyze(
        history: _history(count: 20, lux: 2, uva: 0.01, uvb: 0),
      );

      expect(analysis.latest!.state, EnvironmentContextState.unknown);
    });

    test('night fallback resolves darkness to indoor on a stable room climate', () {
      final analysis = EnvironmentContextClassifier.analyze(
        history: _history(
          count: 20,
          lux: 2,
          uva: 0.01,
          uvb: 0,
          temperature: (_) => 22.0,
        ),
      );

      expect(analysis.latest!.state, EnvironmentContextState.indoor);
    });

    test('night fallback stays out when the temperature is not stable', () {
      final analysis = EnvironmentContextClassifier.analyze(
        history: _history(
          count: 20,
          lux: 2,
          uva: 0.01,
          uvb: 0,
          temperature: (index) => index.isEven ? 22.0 : 23.5,
        ),
      );

      expect(analysis.latest!.state, EnvironmentContextState.unknown);
    });

    test('night fallback stays out when the room is too cold for a heated room', () {
      final analysis = EnvironmentContextClassifier.analyze(
        history: _history(
          count: 20,
          lux: 2,
          uva: 0.01,
          uvb: 0,
          temperature: (_) => 4.0,
        ),
      );

      expect(analysis.latest!.state, EnvironmentContextState.unknown);
    });

    test('skips points without optical data', () {
      final analysis = EnvironmentContextClassifier.analyze(
        history: [
          _point(timestamp: _start, temperature: 21),
          _point(timestamp: _start.add(const Duration(seconds: 30)), lux: 400, uva: 0.12, uvb: 0),
        ],
      );

      expect(analysis.samples, hasLength(1));
    });

    test('is empty for an empty history', () {
      final analysis = EnvironmentContextClassifier.analyze(history: []);
      expect(analysis.isEmpty, isTrue);
      expect(analysis.latest, isNull);
    });
  });

  group('EnvironmentContextTracker', () {
    test('streaming one point at a time matches replaying the whole history', () {
      final history = [
        ..._history(count: 6, lux: 10000, uva: 700, uvb: 21, infrared: 3600, fullSpectrum: 10000),
        ..._history(count: 6, lux: 400, uva: 0.12, uvb: 0, infrared: 56, fullSpectrum: 400)
            .map((e) => _shift(e, const Duration(minutes: 3))),
      ];

      final tracker = EnvironmentContextTracker();
      final streamed = [for (final point in history) tracker.add(point)!.state];
      final replayed =
          EnvironmentContextClassifier.analyze(history: history).samples.map((e) => e.state);

      expect(streamed, replayed);
    });

    test('returns null for measurements without light and UV data', () {
      final tracker = EnvironmentContextTracker();
      expect(tracker.add(_point(timestamp: _start, temperature: 21)), isNull);
    });

    test('reports the raw features alongside the reading', () {
      final tracker = EnvironmentContextTracker();
      final sample = tracker.add(
        _point(timestamp: _start, lux: 1000, uva: 70, uvb: 2.1, infrared: 380, fullSpectrum: 1000),
      )!;

      expect(sample.features.kUv, closeTo(0.07, 1e-6));
      expect(sample.features.beta, closeTo(0.03, 1e-6));
      expect(sample.reading.score, sample.score);
    });
  });

  group('stampAll', () {
    test('fills in missing readings and keeps existing ones', () {
      final history = _history(count: 5, lux: 400, uva: 0.12, uvb: 0);
      const preset = EnvironmentContextReading(
        state: EnvironmentContextState.outdoor,
        score: 0.9,
        confidence: 0.9,
      );
      history[1].environment = preset;

      EnvironmentContextClassifier.stampAll(history);

      expect(history[1].environment, same(preset));
      expect(history.every((e) => e.environment != null), isTrue);
    });

    test('leaves measurements without light and UV data alone', () {
      final history = [_point(timestamp: _start, temperature: 21)];
      EnvironmentContextClassifier.stampAll(history);
      expect(history.single.environment, isNull);
    });
  });

  group('analyze with stored readings', () {
    test('reports the stored classification instead of recomputing it', () {
      final history = _history(count: 3, lux: 400, uva: 0.12, uvb: 0);
      for (final point in history) {
        point.environment = const EnvironmentContextReading(
          state: EnvironmentContextState.outdoor,
          score: 0.77,
          confidence: 0.77,
        );
      }

      final analysis = EnvironmentContextClassifier.analyze(history: history);

      expect(analysis.latest!.state, EnvironmentContextState.outdoor);
      expect(analysis.latest!.score, 0.77);
    });
  });

  group('formatting', () {
    test('score carries an explicit sign', () {
      expect(EnvironmentContextClassifier.formatScore(0.618), '+0.62');
      expect(EnvironmentContextClassifier.formatScore(-0.618), '-0.62');
    });

    test('confidence is rendered as whole percent', () {
      expect(EnvironmentContextClassifier.formatConfidence(0.853), '85 %');
      expect(EnvironmentContextClassifier.formatConfidence(1), '100 %');
    });
  });
}
