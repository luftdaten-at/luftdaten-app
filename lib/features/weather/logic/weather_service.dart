import 'package:flutter/foundation.dart';
import 'package:luftdaten.at/features/weather/data/weather_snapshot.dart';
import 'package:luftdaten.at/features/weather/logic/geosphere_client.dart';
import 'package:luftdaten.at/features/weather/logic/open_meteo_client.dart';

/// Fetches and caches weather inputs for the UTCI tile.
class WeatherService extends ChangeNotifier {
  WeatherService({
    OpenMeteoClient? openMeteo,
    GeosphereClient? geosphere,
  })  : _openMeteo = openMeteo ?? OpenMeteoClient(),
        _geosphere = geosphere ?? GeosphereClient();

  static const refreshInterval = Duration(minutes: 15);

  final OpenMeteoClient _openMeteo;
  final GeosphereClient _geosphere;

  WeatherSnapshot? _latest;
  DateTime? _lastFetch;
  bool _refreshing = false;

  WeatherSnapshot? get latest => _latest;

  /// Refresh when stale or when [force] is true.
  Future<void> refreshIfStale({
    required double latitude,
    required double longitude,
    bool force = false,
  }) async {
    if (_refreshing) return;
    if (!force &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < refreshInterval) {
      return;
    }
    await refresh(latitude: latitude, longitude: longitude);
  }

  Future<void> refresh({
    required double latitude,
    required double longitude,
  }) async {
    _refreshing = true;
    try {
      final fetchedAt = DateTime.now().toUtc();
      final om = await _openMeteo.fetchCurrent(
        latitude: latitude,
        longitude: longitude,
      );

      TawesCurrent? tawes;
      TawesNearestResult? nearest;
      if (GeosphereClient.isInAustria(latitude, longitude)) {
        nearest = await _geosphere.nearestStation(latitude, longitude);
        if (nearest != null) {
          tawes = await _geosphere.fetchCurrent(nearest.station.id);
        }
      }

      String? v10Source;
      double? v10;
      if (tawes?.windSpeedMs != null) {
        v10 = tawes!.windSpeedMs;
        v10Source = 'tawes';
      } else if (om?.windSpeed10m != null) {
        v10 = om!.windSpeed10m;
        v10Source = 'open_meteo';
      } else {
        v10 = 1.0;
        v10Source = 'fallback';
      }

      final observedAt = _latestObserved(tawes, om) ?? fetchedAt;

      _latest = WeatherSnapshot(
        observedAt: observedAt,
        fetchedAt: fetchedAt,
        latitude: latitude,
        longitude: longitude,
        t2mC: tawes?.temperatureC ?? om?.t2mC,
        rh2mPercent: tawes?.relativeHumidityPercent ?? om?.rh2mPercent,
        v10Ms: v10,
        v10Source: v10Source,
        cloudFraction: om?.cloudFraction,
        globalHorizontalWm2: om?.globalHorizontalWm2,
        directNormalWm2: om?.directNormalIrradiance,
        diffuseHorizontalWm2: om?.diffuseHorizontalWm2,
        radiationSource: om != null ? 'open_meteo' : null,
        tawesStationId: nearest?.station.id,
        tawesStationDistanceKm: nearest?.distanceKm,
      );
      _lastFetch = DateTime.now();
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  DateTime? _latestObserved(TawesCurrent? tawes, OpenMeteoCurrent? om) {
    final times = <DateTime>[
      if (tawes != null) tawes.observedAt,
      if (om != null) om.observedAt,
    ];
    if (times.isEmpty) return null;
    times.sort();
    return times.last;
  }
}
