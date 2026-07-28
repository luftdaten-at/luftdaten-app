import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/measurements/data/environment_context_reading.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

export 'package:luftdaten.at/features/measurements/data/environment_context_reading.dart';

/// Indoor/outdoor detection from AS7331 UV bands plus TSL2591 light channels.
///
/// Implements the classifier designed in `innen-aussen-erkennung.md`: every
/// decision feature is a *ratio* rather than an absolute value, which makes it
/// independent of gain, integration time, window transmission and — most
/// importantly — badge orientation. A body-worn sensor sees the sun up to 20x
/// brighter depending on body rotation, but the spectrum barely changes.
///
/// Runs on the app side rather than in the firmware. [EnvironmentContextTracker]
/// classifies a live measurement stream point by point; [analyze] replays a
/// recorded trip for charts and for trips that were imported without a stored
/// classification.
class EnvironmentContextClassifier {
  EnvironmentContextClassifier._();

  /// UVA noise floor in µW/cm². Below this, UV-based tests are masked out
  /// instead of counted as evidence for "indoor" — otherwise every night would
  /// be classified as indoors.
  static const double noiseUva = 0.05;

  /// Illuminance noise floor in lux.
  static const double noiseLux = 1.0;

  /// Below this illuminance, and without UV signal, the optical features carry
  /// no information at all.
  static const double darknessLux = 5.0;

  /// Score magnitude required to leave the current state.
  static const double switchThreshold = 0.4;

  /// The TSL2591 saturates near this illuminance. Gain and integration time are
  /// not transmitted with the measurement, so full-scale is approximated from
  /// the reported values; saturation is treated as strong evidence for direct
  /// sun rather than as a hard fact.
  static const double saturationLux = 88000;

  /// 16 bit channel ceiling of the TSL2591 ADC.
  static const double channelCeiling = 65535;

  /// Hysteresis: the design asks for 3 matching cycles at a 30 s measurement
  /// interval (= 90 s), which prevents flapping when walking past a window.
  /// Trip sampling in the app is configurable and often much faster, so both
  /// conditions are required and the interval no longer matters.
  static const int minConfirmations = 3;
  static const Duration hysteresisWindow = Duration(seconds: 90);

  /// Night fallback: window over which temperature stability is judged.
  static const Duration climateWindow = Duration(minutes: 10);

  /// Shortest span of temperature history accepted for the night fallback. The
  /// design specifies the full 10 min window; requiring it in full would make
  /// the fallback unusable on short trips.
  static const Duration minClimateSpan = Duration(minutes: 5);

  /// Standard deviation below which room temperature counts as "stable", chosen
  /// in the design to sit above the SHTC3 repeatability of +-0.1 K.
  static const double stableTemperatureSigma = 0.3;
  static const double stableTemperatureMin = 18.0;
  static const double stableTemperatureMax = 27.0;

  /// Soft ramp from -1 (fully indoor) to +1 (fully outdoor), replacing a hard
  /// threshold so that borderline cases degrade gracefully.
  static double ramp(double x, double lo, double hi) {
    final v = 2 * (x - lo) / (hi - lo) - 1;
    return v.clamp(-1.0, 1.0);
  }

  /// Weighted evidence score in [-1, +1]; positive means evidence for outdoors.
  ///
  /// Tests whose inputs sit below the noise floor are masked out with weight 0,
  /// so the result stays neutral instead of drifting to "indoor" in the dark.
  static double scoreOf(EnvironmentContextFeatures features) {
    var numerator = 0.0;
    var denominator = 0.0;

    final uva = features.uva;
    final beta = features.beta;
    // UVB/UVA is the strongest feature: window glass passes UVA but blocks UVB
    // almost completely, and artificial light contains no UVB at all.
    if (uva != null && uva > noiseUva && beta != null) {
      numerator += 3.0 * ramp(beta, 0.003, 0.015);
      denominator += 3.0;
    }

    final lux = features.lux;
    if (lux != null && lux > noiseLux) {
      final kUv = features.kUv;
      if (kUv != null) {
        numerator += 2.0 * ramp(_log10(kUv), -3.3, -2.0);
        denominator += 2.0;
      }
      final rIr = features.rIr;
      if (rIr != null) {
        // Two-sided: daylight sits in a band. LED and fluorescent light fall
        // below it, halogen and incandescent above it.
        final tIr = math.min(ramp(rIr, 0.22, 0.30), -ramp(rIr, 0.48, 0.56));
        numerator += tIr;
        denominator += 1.0;
      }
      numerator += ramp(_log10(lux), 3.0, 3.7);
      denominator += 1.0;
    }

    if (features.saturated) {
      numerator += 1.5;
      denominator += 1.5;
    }

    return denominator > 0 ? numerator / denominator : 0.0;
  }

  /// Replay the classification over a recorded trip.
  ///
  /// Points that already carry a stored classification report that one, so the
  /// app shows what was actually recorded and uploaded rather than a re-run.
  static EnvironmentContextAnalysis analyze({
    required List<MeasuredDataPoint> history,
  }) {
    final tracker = EnvironmentContextTracker();
    final samples = <EnvironmentContextSample>[];
    for (final point in history) {
      final sample = tracker.add(point);
      if (sample == null) continue;
      final stored = point.environment;
      samples.add(stored != null ? sample.withReading(stored) : sample);
    }
    return EnvironmentContextAnalysis(samples: samples);
  }

  /// Fill in classifications for measurements that do not have one yet, used
  /// for trips that arrive in bulk (device log import, older trip files).
  /// Existing readings are left untouched.
  static void stampAll(List<MeasuredDataPoint> history) {
    final tracker = EnvironmentContextTracker();
    for (final point in history) {
      final sample = tracker.add(point);
      if (sample == null) continue;
      point.environment ??= sample.reading;
    }
  }

  /// Extract the optical features of a single measurement, or null when neither
  /// light nor UV data is present.
  static EnvironmentContextFeatures? featuresAt(MeasuredDataPoint point) {
    final lux = firstValue(point, MeasurableQuantity.lux);
    final uva = firstValue(point, MeasurableQuantity.uva);
    final uvb = firstValue(point, MeasurableQuantity.uvb);
    final uvc = firstValue(point, MeasurableQuantity.uvc);
    final visible = firstValue(point, MeasurableQuantity.visible);
    final infrared = firstValue(point, MeasurableQuantity.infrared);
    final fullSpectrum = firstValue(point, MeasurableQuantity.fullSpectrum);

    if (lux == null && uva == null) return null;

    final ch0 = fullSpectrum ??
        (visible != null && infrared != null ? visible + infrared : null);
    final rIr =
        (ch0 != null && infrared != null && ch0 > 0) ? infrared / ch0 : null;

    final saturated = (lux != null && lux >= saturationLux) ||
        [visible, infrared, fullSpectrum]
            .any((e) => e != null && e >= channelCeiling);

    return EnvironmentContextFeatures(
      lux: lux,
      uva: uva,
      uvb: uvb,
      uvc: uvc,
      rIr: rIr,
      saturated: saturated,
    );
  }

  static Color stateColor(EnvironmentContextState state) => switch (state) {
        EnvironmentContextState.outdoor => const Color(0xFF2E7D32),
        EnvironmentContextState.indoorWindow => const Color(0xFFEF6C00),
        EnvironmentContextState.indoor => const Color(0xFF1565C0),
        EnvironmentContextState.unknown => Colors.grey.shade700,
      };

  static IconData stateIcon(EnvironmentContextState state) => switch (state) {
        EnvironmentContextState.outdoor => Icons.wb_sunny_outlined,
        EnvironmentContextState.indoorWindow => Icons.sensor_window_outlined,
        EnvironmentContextState.indoor => Icons.home_outlined,
        EnvironmentContextState.unknown => Icons.help_outline,
      };

  static String formatScore(double score) =>
      '${score >= 0 ? '+' : '-'}${score.abs().toStringAsFixed(2)}';

  static String formatConfidence(double confidence) =>
      '${(confidence * 100).round()} %';

  static double? firstValue(MeasuredDataPoint point, MeasurableQuantity q) {
    for (final sensorData in point.sensorData) {
      final value = sensorData.values[q];
      if (value != null) return value;
    }
    return null;
  }

  static double _log10(double value) => math.log(value) / math.ln10;
}

/// Runs the classifier over a live measurement stream, one point at a time.
///
/// Holds the hysteresis and confidence state of the design's state machine, so
/// one tracker belongs to exactly one trip.
class EnvironmentContextTracker {
  EnvironmentContextState _state = EnvironmentContextState.unknown;
  EnvironmentContextState _candidate = EnvironmentContextState.unknown;
  int _pending = 0;
  DateTime? _candidateSince;
  DateTime? _previousTimestamp;
  double _confidence = 0;
  final List<_ClimateSample> _climate = [];

  EnvironmentContextState get state => _state;

  /// Classify one measurement, or null when it carries no light and no UV data.
  EnvironmentContextSample? add(MeasuredDataPoint point) {
    final temperature = EnvironmentContextClassifier.firstValue(
      point,
      MeasurableQuantity.temperature,
    );
    if (temperature != null) {
      _climate.add(_ClimateSample(point.timestamp, temperature));
      _climate.removeWhere(
        (e) =>
            point.timestamp.difference(e.timestamp) >
            EnvironmentContextClassifier.climateWindow,
      );
    }

    final features = EnvironmentContextClassifier.featuresAt(point);
    if (features == null) return null;

    final EnvironmentContextState target;
    final double score;
    if (features.isWindowSignature) {
      // Evaluated before the score and overriding it: plenty of UVA with no
      // UVB is unambiguous, and thermally relevant because window radiation
      // lifts the mean radiant temperature well above air temperature.
      target = EnvironmentContextState.indoorWindow;
      score = 0.0;
    } else {
      score = EnvironmentContextClassifier.scoreOf(features);
      if (features.isDark) {
        target = _hasStableRoomClimate()
            ? EnvironmentContextState.indoor
            : EnvironmentContextState.unknown;
      } else if (score > EnvironmentContextClassifier.switchThreshold) {
        target = EnvironmentContextState.outdoor;
      } else if (score < -EnvironmentContextClassifier.switchThreshold) {
        target = EnvironmentContextState.indoor;
      } else {
        target = _state;
      }
    }

    _applyHysteresis(target, point.timestamp);

    if (_state == EnvironmentContextState.indoorWindow &&
        features.isWindowSignature) {
      // The window rule is deterministic, so it does not inherit the score of
      // 0 as its confidence.
      _confidence = 1.0;
    } else if (_state == EnvironmentContextState.unknown) {
      _confidence *= 0.9;
    } else {
      _confidence = score.abs();
    }

    _previousTimestamp = point.timestamp;

    return EnvironmentContextSample(
      timestamp: point.timestamp,
      reading: EnvironmentContextReading(
        state: _state,
        score: score,
        confidence: _confidence.clamp(0.0, 1.0),
        saturated: features.saturated,
        uvcAnomaly: features.hasUvcAnomaly,
      ),
      features: features,
    );
  }

  /// Switch state only after [minConfirmations] matching cycles that also span
  /// [EnvironmentContextClassifier.hysteresisWindow], measured from the last
  /// measurement still in the old state.
  void _applyHysteresis(EnvironmentContextState target, DateTime timestamp) {
    if (target == _state) {
      _candidate = _state;
      _pending = 0;
      _candidateSince = null;
      return;
    }
    if (target != _candidate) {
      _candidate = target;
      _pending = 1;
      _candidateSince = _previousTimestamp ?? timestamp;
      return;
    }

    _pending++;
    final since = _candidateSince ?? timestamp;
    if (_pending >= EnvironmentContextClassifier.minConfirmations &&
        timestamp.difference(since) >=
            EnvironmentContextClassifier.hysteresisWindow) {
      _state = target;
      _pending = 0;
      _candidateSince = null;
    }
  }

  /// Night fallback: outdoors and a dark room look identical to both optical
  /// sensors, so a room-temperature plateau is used as additional evidence.
  bool _hasStableRoomClimate() {
    if (_climate.length < EnvironmentContextClassifier.minConfirmations) {
      return false;
    }
    final span = _climate.last.timestamp.difference(_climate.first.timestamp);
    if (span < EnvironmentContextClassifier.minClimateSpan) return false;

    final values = _climate.map((e) => e.value).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean <= EnvironmentContextClassifier.stableTemperatureMin ||
        mean >= EnvironmentContextClassifier.stableTemperatureMax) {
      return false;
    }
    final variance =
        values.map((e) => (e - mean) * (e - mean)).reduce((a, b) => a + b) /
            values.length;
    return math.sqrt(variance) <
        EnvironmentContextClassifier.stableTemperatureSigma;
  }
}

class EnvironmentContextFeatures {
  const EnvironmentContextFeatures({
    this.lux,
    this.uva,
    this.uvb,
    this.uvc,
    this.rIr,
    this.saturated = false,
  });

  /// Illuminance in lux.
  final double? lux;

  /// UV irradiance per band in µW/cm².
  final double? uva;
  final double? uvb;
  final double? uvc;

  /// Infrared share CH1/CH0 of the TSL2591.
  final double? rIr;

  /// TSL2591 at full scale, which practically means direct sun.
  final bool saturated;

  /// How UV-rich this light is, in µW·cm⁻²·lux⁻¹.
  double? get kUv {
    final lux = this.lux;
    final uva = this.uva;
    if (lux == null || uva == null || lux <= 0) return null;
    return (uva + 1e-6) / lux;
  }

  /// UVB/UVA — the glass discriminator.
  double? get beta {
    final uva = this.uva;
    final uvb = this.uvb;
    if (uva == null || uvb == null || uva <= 0) return null;
    return uvb / uva;
  }

  /// UVA without UVB above a usable light level: light that has passed through
  /// window glass.
  bool get isWindowSignature {
    final lux = this.lux;
    final kUv = this.kUv;
    final beta = this.beta;
    if (lux == null || kUv == null || beta == null) return false;
    return kUv > 0.003 && beta < 0.005 && lux > 200;
  }

  bool get isDark {
    final lux = this.lux;
    if (lux == null || lux >= EnvironmentContextClassifier.darknessLux) {
      return false;
    }
    final uva = this.uva;
    return uva == null || uva < EnvironmentContextClassifier.noiseUva;
  }

  /// UVC never reaches the ground — the ozone layer absorbs it completely. A
  /// significant reading means either an artificial UVC source in the room or
  /// spectral crosstalk from very high UVB, so it is a plausibility flag rather
  /// than a classification feature.
  bool get hasUvcAnomaly {
    final uvc = this.uvc;
    return uvc != null && uvc > EnvironmentContextClassifier.noiseUva;
  }
}

class EnvironmentContextSample {
  const EnvironmentContextSample({
    required this.timestamp,
    required this.reading,
    required this.features,
  });

  final DateTime timestamp;
  final EnvironmentContextReading reading;
  final EnvironmentContextFeatures features;

  EnvironmentContextState get state => reading.state;

  double get score => reading.score;

  double get confidence => reading.confidence;

  EnvironmentContextSample withReading(EnvironmentContextReading reading) =>
      EnvironmentContextSample(
        timestamp: timestamp,
        reading: reading,
        features: features,
      );
}

class EnvironmentContextAnalysis {
  const EnvironmentContextAnalysis({required this.samples});

  final List<EnvironmentContextSample> samples;

  EnvironmentContextSample? get latest => samples.lastOrNull;

  bool get isEmpty => samples.isEmpty;
}

class _ClimateSample {
  const _ClimateSample(this.timestamp, this.value);

  final DateTime timestamp;
  final double value;
}
