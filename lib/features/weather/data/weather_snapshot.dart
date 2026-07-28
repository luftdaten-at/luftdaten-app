/// Weather inputs used for UTCI, stored per measurement for later recompute.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.observedAt,
    required this.fetchedAt,
    required this.latitude,
    required this.longitude,
    this.t2mC,
    this.rh2mPercent,
    this.v10Ms,
    this.v10Source,
    this.cloudFraction,
    this.globalHorizontalWm2,
    this.directNormalWm2,
    this.diffuseHorizontalWm2,
    this.radiationSource,
    this.tawesStationId,
    this.tawesStationDistanceKm,
  });

  final DateTime observedAt;
  final DateTime fetchedAt;
  final double latitude;
  final double longitude;

  final double? t2mC;
  final double? rh2mPercent;

  /// Wind at 10 m after urban correction [m/s].
  final double? v10Ms;

  /// `tawes`, `open_meteo`, or `fallback`.
  final String? v10Source;

  /// Cloud cover fraction 0…1.
  final double? cloudFraction;

  final double? globalHorizontalWm2;
  final double? directNormalWm2;
  final double? diffuseHorizontalWm2;

  /// `open_meteo`.
  final String? radiationSource;

  final String? tawesStationId;
  final double? tawesStationDistanceKm;

  bool get hasRadiation =>
      globalHorizontalWm2 != null &&
      directNormalWm2 != null &&
      diffuseHorizontalWm2 != null;

  Map<String, dynamic> toJson() => {
        'observed_at': observedAt.toUtc().toIso8601String(),
        'fetched_at': fetchedAt.toUtc().toIso8601String(),
        'lat': latitude,
        'lon': longitude,
        if (t2mC != null) 't2m': t2mC,
        if (rh2mPercent != null) 'rh2m': rh2mPercent,
        if (v10Ms != null) 'v10': v10Ms,
        if (v10Source != null) 'v10_source': v10Source,
        if (cloudFraction != null) 'cloud': cloudFraction,
        if (globalHorizontalWm2 != null) 'g_h': globalHorizontalWm2,
        if (directNormalWm2 != null) 'i_n': directNormalWm2,
        if (diffuseHorizontalWm2 != null) 'd_h': diffuseHorizontalWm2,
        if (radiationSource != null) 'radiation_source': radiationSource,
        if (tawesStationId != null) 'tawes_station': tawesStationId,
        if (tawesStationDistanceKm != null)
          'tawes_distance_km': tawesStationDistanceKm,
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) => WeatherSnapshot(
        observedAt: DateTime.parse(json['observed_at'] as String),
        fetchedAt: DateTime.parse(json['fetched_at'] as String),
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lon'] as num).toDouble(),
        t2mC: (json['t2m'] as num?)?.toDouble(),
        rh2mPercent: (json['rh2m'] as num?)?.toDouble(),
        v10Ms: (json['v10'] as num?)?.toDouble(),
        v10Source: json['v10_source'] as String?,
        cloudFraction: (json['cloud'] as num?)?.toDouble(),
        globalHorizontalWm2: (json['g_h'] as num?)?.toDouble(),
        directNormalWm2: (json['i_n'] as num?)?.toDouble(),
        diffuseHorizontalWm2: (json['d_h'] as num?)?.toDouble(),
        radiationSource: json['radiation_source'] as String?,
        tawesStationId: json['tawes_station'] as String?,
        tawesStationDistanceKm: (json['tawes_distance_km'] as num?)?.toDouble(),
      );
}
