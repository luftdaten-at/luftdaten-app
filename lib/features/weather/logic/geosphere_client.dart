import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:luftdaten.at/features/weather/logic/open_meteo_client.dart';

/// GeoSphere Austria TAWES current observations client.
class GeosphereClient {
  GeosphereClient({http.Client? client, GetStorage? box})
      : _client = client ?? http.Client(),
        _box = box ?? GetStorage('geosphere');

  final http.Client _client;
  final GetStorage _box;

  static const _base = 'https://dataset.api.hub.geosphere.at/v1';
  static const _stationsKey = 'tawes_stations';

  /// Rough Austria bounding box for TAWES eligibility.
  static bool isInAustria(double lat, double lon) =>
      lat >= 46.0 && lat <= 49.2 && lon >= 9.0 && lon <= 17.2;

  Future<List<TawesStation>> _stations() async {
    final cached = _box.read<List<dynamic>>(_stationsKey);
    if (cached != null && cached.isNotEmpty) {
      return cached
          .map((e) => TawesStation.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }

    final uri = Uri.parse('$_base/station/current/tawes-v1-10min/metadata');
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) return const [];

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final stations = (json['stations'] as List?)
            ?.map((e) => TawesStation.fromJson((e as Map).cast<String, dynamic>()))
            .where((s) => s.isActive)
            .toList() ??
        const <TawesStation>[];

    _box.write(_stationsKey, stations.map((e) => e.toJson()).toList());
    return stations;
  }

  Future<TawesNearestResult?> nearestStation(double lat, double lon) async {
    if (!isInAustria(lat, lon)) return null;
    final stations = await _stations();
    if (stations.isEmpty) return null;

    TawesStation? best;
    var bestDist = double.infinity;
    for (final s in stations) {
      final d = haversineKm(lat, lon, s.lat, s.lon);
      if (d < bestDist) {
        bestDist = d;
        best = s;
      }
    }
    if (best == null) return null;
    return TawesNearestResult(station: best, distanceKm: bestDist);
  }

  Future<TawesCurrent?> fetchCurrent(String stationId) async {
    final uri = Uri.parse('$_base/station/current/tawes-v1-10min').replace(
      queryParameters: {
        'parameters': 'FFAM,FF,DD,TL,RF',
        'station_ids': stationId,
        'output_format': 'geojson',
      },
    );
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) return null;

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final timestamps = (json['timestamps'] as List?)?.cast<String>();
    final features = json['features'] as List?;
    if (features == null || features.isEmpty) return null;

    final props = (features.first as Map)['properties'] as Map<String, dynamic>;
    final params = props['parameters'] as Map<String, dynamic>;

    double? val(String key) {
      final block = params[key] as Map<String, dynamic>?;
      final data = block?['data'] as List?;
      if (data == null || data.isEmpty) return null;
      return (data.first as num?)?.toDouble();
    }

    final observedAt = timestamps != null && timestamps.isNotEmpty
        ? DateTime.parse(timestamps.first)
        : DateTime.now().toUtc();

    return TawesCurrent(
      observedAt: observedAt,
      windSpeedMs: val('FFAM') ?? val('FF'),
      temperatureC: val('TL'),
      relativeHumidityPercent: val('RF'),
      stationId: stationId,
    );
  }
}

class TawesStation {
  const TawesStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.isActive,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lon': lon,
        'active': isActive,
      };

  factory TawesStation.fromJson(Map<String, dynamic> json) => TawesStation(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        isActive: json['is_active'] as bool? ?? true,
      );
}

class TawesNearestResult {
  const TawesNearestResult({required this.station, required this.distanceKm});
  final TawesStation station;
  final double distanceKm;
}

class TawesCurrent {
  const TawesCurrent({
    required this.observedAt,
    this.windSpeedMs,
    this.temperatureC,
    this.relativeHumidityPercent,
    required this.stationId,
  });

  final DateTime observedAt;
  final double? windSpeedMs;
  final double? temperatureC;
  final double? relativeHumidityPercent;
  final String stationId;
}
