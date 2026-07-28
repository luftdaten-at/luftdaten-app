/// Classified wearing environment, used to pick the matching comfort model
/// downstream (UTCI outdoors, PMV/PPD indoors).
enum EnvironmentContextState {
  /// Darkness or ambiguous evidence: the previous state is held.
  unknown,

  /// Indoors, artificial light or dark.
  indoor,

  /// Indoors but close to a window: UVA present, UVB filtered out by glass.
  indoorWindow,

  /// Open sky access.
  outdoor;

  static EnvironmentContextState fromName(String? name) =>
      values.where((e) => e.name == name).firstOrNull ?? unknown;
}

/// Outcome of the indoor/outdoor classification for a single measurement.
///
/// Stored alongside the measurement it was derived from and uploaded with it, so
/// that a recorded trip states which environment it was recorded in instead of
/// leaving that to be re-derived by every consumer.
///
/// The raw features behind the decision (illuminance, UVA, UVB, the light
/// channels) are not repeated here — they are already persisted as ordinary
/// sensor readings on the same data point, which is what the offline threshold
/// calibration needs.
class EnvironmentContextReading {
  const EnvironmentContextReading({
    required this.state,
    required this.score,
    required this.confidence,
    this.saturated = false,
    this.uvcAnomaly = false,
  });

  final EnvironmentContextState state;

  /// Weighted evidence score in [-1, +1]; positive means evidence for outdoors.
  /// Always 0 when [state] came from the deterministic window-seat rule.
  final double score;

  /// 0..1, meant for weighting by downstream models.
  final double confidence;

  /// The light sensor was at full scale, which practically means direct sun.
  final bool saturated;

  /// UVC was measured, which cannot happen under open sky.
  final bool uvcAnomaly;

  List<String> get flags => [
        if (saturated) saturatedFlag,
        if (uvcAnomaly) uvcAnomalyFlag,
      ];

  static const saturatedFlag = 'saturated';
  static const uvcAnomalyFlag = 'uvc_anomaly';

  Map<String, dynamic> toJson() {
    final flags = this.flags;
    return {
      'state': state.name,
      'score': score,
      'confidence': confidence,
      if (flags.isNotEmpty) 'flags': flags,
    };
  }

  factory EnvironmentContextReading.fromJson(Map<String, dynamic> json) {
    final flags =
        (json['flags'] as List?)?.map((e) => e.toString()).toSet() ?? const <String>{};
    return EnvironmentContextReading(
      state: EnvironmentContextState.fromName(json['state'] as String?),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      saturated: flags.contains(saturatedFlag),
      uvcAnomaly: flags.contains(uvcAnomalyFlag),
    );
  }

  @override
  String toString() =>
      'EnvironmentContextReading(${state.name}, score: $score, confidence: $confidence, flags: $flags)';
}
