import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Open-Meteo forecast API client for radiation and fallback wind.
class OpenMeteoClient {
  OpenMeteoClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _base = 'https://api.open-meteo.com/v1/forecast';

  Future<OpenMeteoCurrent?> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'current': [
        'temperature_2m',
        'relative_humidity_2m',
        'wind_speed_10m',
        'cloud_cover',
        'shortwave_radiation',
        'direct_radiation',
        'diffuse_radiation',
        'direct_normal_irradiance',
      ].join(','),
      'wind_speed_unit': 'ms',
    });

    final resp = await _client.get(uri);
    if (resp.statusCode != 200) return null;

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>?;
    if (current == null) return null;

    final timeStr = current['time'] as String?;
    final observedAt = timeStr != null
        ? DateTime.parse('${timeStr}Z')
        : DateTime.now().toUtc();

    return OpenMeteoCurrent(
      observedAt: observedAt,
      t2mC: (current['temperature_2m'] as num?)?.toDouble(),
      rh2mPercent: (current['relative_humidity_2m'] as num?)?.toDouble(),
      windSpeed10m: (current['wind_speed_10m'] as num?)?.toDouble(),
      cloudCoverPercent: (current['cloud_cover'] as num?)?.toDouble(),
      globalHorizontalWm2: (current['shortwave_radiation'] as num?)?.toDouble(),
      directHorizontalWm2: (current['direct_radiation'] as num?)?.toDouble(),
      diffuseHorizontalWm2: (current['diffuse_radiation'] as num?)?.toDouble(),
      directNormalIrradiance: (current['direct_normal_irradiance'] as num?)?.toDouble(),
    );
  }
}

class OpenMeteoCurrent {
  const OpenMeteoCurrent({
    required this.observedAt,
    this.t2mC,
    this.rh2mPercent,
    this.windSpeed10m,
    this.cloudCoverPercent,
    this.globalHorizontalWm2,
    this.directHorizontalWm2,
    this.diffuseHorizontalWm2,
    this.directNormalIrradiance,
  });

  final DateTime observedAt;
  final double? t2mC;
  final double? rh2mPercent;
  final double? windSpeed10m;
  final double? cloudCoverPercent;
  final double? globalHorizontalWm2;
  final double? directHorizontalWm2;
  final double? diffuseHorizontalWm2;
  final double? directNormalIrradiance;

  double? get cloudFraction =>
      cloudCoverPercent != null ? cloudCoverPercent! / 100.0 : null;
}

/// Haversine distance [km].
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * math.pi / 180;
