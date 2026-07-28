import 'package:get_storage/get_storage.dart';

/// Self-calibrating body-heat offset ΔT_body (section 3.1).
///
/// Median of (T_badge − T2M_api) over valid outdoor night samples in the
/// trailing 24 h, persisted across trips.
class BodyHeatCalibrationStore {
  BodyHeatCalibrationStore({GetStorage? box})
      : _box = box ?? GetStorage('bodyHeatCalibration');

  static const minSamples = 30;
  static const window = Duration(hours: 24);
  static const maxDtPerSecond = 0.02;
  static const nightLux = 5.0;
  static const minWindMs = 1.5;

  /// Solar heating correction [K/(W/m²)] for daytime badge offset.
  static const kSol = 0.004;

  final GetStorage _box;
  static const _samplesKey = 'samples';
  static const _lastDeltaKey = 'lastDelta';

  Future<void> init() async {
    await GetStorage.init('bodyHeatCalibration');
  }

  List<_CalibrationSample> get _samples {
    final raw = _box.read<List<dynamic>>(_samplesKey) ?? const [];
    return raw
        .map((e) => _CalibrationSample.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  void _saveSamples(List<_CalibrationSample> samples) {
    _box.write(
      _samplesKey,
      samples.map((e) => e.toJson()).toList(),
    );
  }

  double? get lastPersistedDelta => (_box.read(_lastDeltaKey) as num?)?.toDouble();

  /// Record a candidate sample when all gates pass.
  void maybeRecord({
    required DateTime timestamp,
    required double tBadgeC,
    required double t2mApiC,
    required double lux,
    required double v10Ms,
    required double? previousTBadgeC,
    required DateTime? previousTimestamp,
    required bool isOutdoor,
  }) {
    if (!isOutdoor || lux >= nightLux || v10Ms <= minWindMs) return;

    if (previousTBadgeC != null && previousTimestamp != null) {
      final dt = timestamp.difference(previousTimestamp).inMilliseconds / 1000.0;
      if (dt > 0) {
        final rate = (tBadgeC - previousTBadgeC).abs() / dt;
        if (rate >= maxDtPerSecond) return;
      }
    }

    final samples = _samples
      ..add(_CalibrationSample(timestamp, tBadgeC - t2mApiC))
      ..removeWhere((e) => timestamp.difference(e.timestamp) > window);
    _saveSamples(samples);
  }

  /// Current ΔT_body [K], or null when never calibrated.
  BodyHeatCalibrationResult delta({
    required DateTime now,
  }) {
    final samples = _samples
        .where((e) => now.difference(e.timestamp) <= window)
        .map((e) => e.deltaK)
        .toList()
      ..sort();

    if (samples.length >= minSamples) {
      final median = _median(samples);
      _box.write(_lastDeltaKey, median);
      return BodyHeatCalibrationResult(
        deltaK: median,
        sampleCount: samples.length,
        usingFallback: false,
      );
    }

    final fallback = lastPersistedDelta;
    if (fallback != null) {
      return BodyHeatCalibrationResult(
        deltaK: fallback,
        sampleCount: samples.length,
        usingFallback: true,
      );
    }

    return BodyHeatCalibrationResult(
      deltaK: null,
      sampleCount: samples.length,
      usingFallback: false,
    );
  }

  /// Correct badge air temperature [°C].
  double correctedAirTemp({
    required double tBadgeC,
    required double? deltaK,
    required double fSun,
    required double globalHorizontalWm2,
  }) {
    final base = deltaK != null ? tBadgeC - deltaK : tBadgeC;
    return base - kSol * fSun * globalHorizontalWm2;
  }

  static double _median(List<double> sorted) {
    final n = sorted.length;
    if (n.isOdd) return sorted[n ~/ 2];
    return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
  }
}

class BodyHeatCalibrationResult {
  const BodyHeatCalibrationResult({
    required this.deltaK,
    required this.sampleCount,
    required this.usingFallback,
  });

  final double? deltaK;
  final int sampleCount;
  final bool usingFallback;

  bool get isCalibrated => deltaK != null && !usingFallback;
}

class _CalibrationSample {
  const _CalibrationSample(this.timestamp, this.deltaK);

  final DateTime timestamp;
  final double deltaK;

  Map<String, dynamic> toJson() => {
        't': timestamp.toIso8601String(),
        'd': deltaK,
      };

  factory _CalibrationSample.fromJson(Map<String, dynamic> json) =>
      _CalibrationSample(
        DateTime.parse(json['t'] as String),
        (json['d'] as num).toDouble(),
      );
}
