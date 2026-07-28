import 'dart:math' as math;

import 'package:luftdaten.at/features/measurements/logic/environment_context.dart';

/// Sun/shade exposure factor f_sun in [0, 1] from badge light sensors.
class SunExposure {
  SunExposure._();

  /// Daylight efficacy for σ_lux comparison [lm/W].
  static const double daylightEfficacy = 110.0;

  /// Instantaneous f_sun from spectral features and API global radiation.
  static double instantaneous({
    required EnvironmentContextFeatures features,
    required double globalHorizontalWm2,
  }) {
    if (globalHorizontalWm2 <= 0) return 0;

    final lux = features.lux;
    final rIr = features.rIr;
    final kUv = features.kUv;

    var sum = 0.0;
    var weight = 0.0;

    if (lux != null && lux > 0) {
      final sigmaLux = lux / (daylightEfficacy * globalHorizontalWm2);
      sum += 0.5 * EnvironmentContextClassifier.ramp(sigmaLux, 0.15, 0.40);
      weight += 0.5;
    }
    if (rIr != null) {
      sum += 0.3 * EnvironmentContextClassifier.ramp(rIr, 0.34, 0.42);
      weight += 0.3;
    }
    if (kUv != null && kUv > 0) {
      final kUvInv = -_log10(kUv);
      sum += 0.2 * EnvironmentContextClassifier.ramp(kUvInv, 2.4, 2.9);
      weight += 0.2;
    }

    if (weight <= 0) return 0;
    return (sum / weight).clamp(0.0, 1.0);
  }

  static double _log10(double v) => math.log(v) / math.ln10;
}

/// Maximum filter over a sliding window (design: 5 minutes).
class SunExposureFilter {
  SunExposureFilter({this.window = const Duration(minutes: 5)});

  final Duration window;
  final List<_SunSample> _samples = [];

  double add({
    required DateTime timestamp,
    required double fSun,
  }) {
    _samples.add(_SunSample(timestamp, fSun));
    _samples.removeWhere((e) => timestamp.difference(e.timestamp) > window);
    if (_samples.isEmpty) return 0;
    return _samples.map((e) => e.fSun).reduce(math.max);
  }

  void clear() => _samples.clear();
}

class _SunSample {
  const _SunSample(this.timestamp, this.fSun);
  final DateTime timestamp;
  final double fSun;
}
