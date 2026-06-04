import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/map/logic/http_provider.dart';

/// Outcome of one wizard polling attempt against api.luftdaten.at.
enum SetupVerificationOutcome {
  /// Still waiting (no measurements yet, or only partial progress).
  pending,

  /// Measurements and geo match expectations.
  completeSuccess,

  /// Measurements OK; geo missing or outside tolerance.
  successMeasurementsOnly,

  /// No recent measurements in API (station may still be booting).
  noMeasurementsYet,

  /// Phone/network error contacting the API.
  networkError,
}

class SetupVerificationAttemptResult {
  const SetupVerificationAttemptResult({
    required this.outcome,
    this.measurementsFound = false,
    this.geoFound = false,
    this.geoMatchesExpected = false,
    this.latestMeasurementTime,
    this.apiLatitude,
    this.apiLongitude,
    this.geoDistanceMeters,
    this.errorMessage,
  });

  final SetupVerificationOutcome outcome;
  final bool measurementsFound;
  final bool geoFound;
  final bool geoMatchesExpected;
  final DateTime? latestMeasurementTime;
  final double? apiLatitude;
  final double? apiLongitude;
  final double? geoDistanceMeters;
  final String? errorMessage;
}

/// Polls Luftdaten.at for first measurements and geo after Air Station setup.
class AirStationSetupVerification {
  AirStationSetupVerification._();

  static const Duration pollInterval = Duration(seconds: 45);
  static const Duration maxWait = Duration(minutes: 12);
  static const Duration measurementMaxAge = Duration(minutes: 30);
  static const Duration historicalLookback = Duration(hours: 2);

  /// Max distance between wizard map pin and API coordinates.
  static const double geoMaxDistanceMeters = 100;

  static const String _apiBase = 'https://api.luftdaten.at';

  /// Resolves API station id (same fallback as dashboard tile).
  static String resolveDeviceId(AirStationConfig? config, String bleName) {
    final fromConfig = config?.deviceId?.trim();
    if (fromConfig != null && fromConfig.isNotEmpty) return fromConfig;
    final parts = bleName.split('-');
    if (parts.length > 1) {
      return '${parts.last}AAA';
    }
    return bleName;
  }

  static bool hasValidExpectedGeo(double? lat, double? lon) {
    if (lat == null || lon == null) return false;
    if (lat == 0 && lon == 0) return false;
    return lat.abs() <= 90 && lon.abs() <= 180;
  }

  /// Haversine distance in meters between two WGS84 points.
  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusM = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  static double _toRadians(double deg) => deg * math.pi / 180;

  static Future<SetupVerificationAttemptResult> runAttempt({
    required String deviceId,
    double? expectedLatitude,
    double? expectedLongitude,
    Map<String, String>? headers,
  }) async {
    final h = headers ?? HttpProvider().httpHeaders;
    try {
      final measurementTime = await _fetchLatestMeasurementTime(deviceId, h);
      final measurementsFound = measurementTime != null &&
          DateTime.now().toUtc().difference(measurementTime.toUtc()) <= measurementMaxAge;

      final geoResult = await _fetchGeoForDevice(deviceId, h);
      final geoFound = geoResult != null;
      var geoMatches = false;
      double? distanceM;

      if (geoFound && hasValidExpectedGeo(expectedLatitude, expectedLongitude)) {
        distanceM = distanceMeters(
          expectedLatitude!,
          expectedLongitude!,
          geoResult.$1,
          geoResult.$2,
        );
        geoMatches = distanceM <= geoMaxDistanceMeters;
      } else if (geoFound && !hasValidExpectedGeo(expectedLatitude, expectedLongitude)) {
        // No expected coords configured — treat geo as OK if station appears on API.
        geoMatches = true;
      }

      if (measurementsFound && geoMatches) {
        return SetupVerificationAttemptResult(
          outcome: SetupVerificationOutcome.completeSuccess,
          measurementsFound: true,
          geoFound: geoFound,
          geoMatchesExpected: true,
          latestMeasurementTime: measurementTime,
          apiLatitude: geoResult?.$1,
          apiLongitude: geoResult?.$2,
          geoDistanceMeters: distanceM,
        );
      }

      if (measurementsFound && (!geoFound || !geoMatches)) {
        return SetupVerificationAttemptResult(
          outcome: SetupVerificationOutcome.successMeasurementsOnly,
          measurementsFound: true,
          geoFound: geoFound,
          geoMatchesExpected: false,
          latestMeasurementTime: measurementTime,
          apiLatitude: geoResult?.$1,
          apiLongitude: geoResult?.$2,
          geoDistanceMeters: distanceM,
        );
      }

      return SetupVerificationAttemptResult(
        outcome: SetupVerificationOutcome.noMeasurementsYet,
        measurementsFound: false,
        geoFound: geoFound,
        geoMatchesExpected: geoMatches,
        latestMeasurementTime: measurementTime,
        apiLatitude: geoResult?.$1,
        apiLongitude: geoResult?.$2,
        geoDistanceMeters: distanceM,
      );
    } catch (e, st) {
      logger.d('AirStationSetupVerification: attempt failed for $deviceId: $e $st');
      return SetupVerificationAttemptResult(
        outcome: SetupVerificationOutcome.networkError,
        errorMessage: e.toString(),
      );
    }
  }

  /// Returns (lat, lon) from GeoJSON feature or null.
  static Future<(double, double)?> _fetchGeoForDevice(
    String deviceId,
    Map<String, String> headers,
  ) async {
    final uri = Uri.parse('$_apiBase/v1/station/current').replace(
      queryParameters: {
        'station_ids': deviceId,
        'last_active': '3600',
        'output_format': 'geojson',
        'calibration_data': 'false',
      },
    );

    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      logger.d('setup verification geo: HTTP ${response.statusCode} for $deviceId');
      return null;
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map) return null;
    final features = decoded['features'];
    if (features is! List) return null;

    for (final f in features) {
      if (f is! Map) continue;
      final feature = Map<String, dynamic>.from(f);
      final m = MapHttpProvider.measurementFromStationCurrentGeoFeature(feature);
      if (m == null) continue;
      if (m.deviceId != deviceId) continue;
      return (m.location.lat, m.location.lon);
    }
    return null;
  }

  static Future<DateTime?> _fetchLatestMeasurementTime(
    String deviceId,
    Map<String, String> headers,
  ) async {
    final start = DateTime.now().toUtc().subtract(historicalLookback);
    final uri = Uri.parse('$_apiBase/v1/station/historical/').replace(
      queryParameters: {
        'station_ids': deviceId,
        'precision': 'all',
        'output_format': 'csv',
        'start': start.toIso8601String(),
      },
    );

    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      logger.d('setup verification historical: HTTP ${response.statusCode} for $deviceId');
      return null;
    }

    DateTime? latest;
    for (final line in response.body.split('\n')) {
      if (line.isEmpty || line.startsWith('device,')) continue;
      final parts = line.split(',');
      if (parts.length < 4) continue;
      try {
        final ts = DateTime.parse(parts[1].trim());
        if (latest == null || ts.isAfter(latest)) {
          latest = ts;
        }
      } catch (_) {
        continue;
      }
    }
    return latest;
  }
}

/// Live status shown on the wizard waiting screen.
class SetupVerificationProgress {
  SetupVerificationProgress({
    this.attemptCount = 0,
    this.measurementsOk,
    this.geoOk,
    this.apiLatitude,
    this.apiLongitude,
    this.geoDistanceMeters,
    this.lastCheckAt,
    this.lastError,
  });

  final int attemptCount;
  final bool? measurementsOk;
  final bool? geoOk;
  final double? apiLatitude;
  final double? apiLongitude;
  final double? geoDistanceMeters;
  final DateTime? lastCheckAt;
  final String? lastError;
}
