import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/thermal_comfort_reading.dart';
import 'package:luftdaten.at/features/measurements/logic/environment_context.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/body_heat_calibration.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/sun_exposure.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_comfort.dart';
import 'package:luftdaten.at/features/weather/data/weather_snapshot.dart';

/// Streaming thermal comfort computation for one trip.
class ThermalComfortTracker {
  ThermalComfortTracker({
    BodyHeatCalibrationStore? calibrationStore,
  }) : _calibrationStore = calibrationStore ?? BodyHeatCalibrationStore();

  final BodyHeatCalibrationStore _calibrationStore;
  final SunExposureFilter _sunFilter = SunExposureFilter();

  double? _previousTBadgeC;
  DateTime? _previousTimestamp;

  double _pmvClothing() => AppSettings.I.pmvClothingInsulation;

  double _cUrban() => AppSettings.I.cUrban;

  ThermalComfortSample? add({
    required MeasuredDataPoint point,
    required EnvironmentContextReading? environment,
    required WeatherSnapshot? weather,
    required bool hasGpsFix,
  }) {
    final tBadge = EnvironmentContextClassifier.firstValue(
      point,
      MeasurableQuantity.temperature,
    );
    final rh = EnvironmentContextClassifier.firstValue(
      point,
      MeasurableQuantity.humidity,
    );
    if (tBadge == null || rh == null) return null;

    final envState = environment?.state ?? EnvironmentContextState.unknown;
    final features = EnvironmentContextClassifier.featuresAt(point);
    final gH = weather?.globalHorizontalWm2 ?? 0.0;

    var fSun = 0.0;
    if (features != null && gH > 0) {
      final instant = SunExposure.instantaneous(
        features: features,
        globalHorizontalWm2: gH,
      );
      fSun = _sunFilter.add(timestamp: point.timestamp, fSun: instant);
    }

    if (weather?.t2mC != null && features?.lux != null) {
      _calibrationStore.maybeRecord(
        timestamp: point.timestamp,
        tBadgeC: tBadge,
        t2mApiC: weather!.t2mC!,
        lux: features!.lux!,
        v10Ms: weather.v10Ms ?? ThermalComfortCalculator.fallbackWindMs,
        previousTBadgeC: _previousTBadgeC,
        previousTimestamp: _previousTimestamp,
        isOutdoor: envState == EnvironmentContextState.outdoor,
      );
    }

    final calibration = _calibrationStore.delta(now: point.timestamp);
    final reading = ThermalComfortCalculator.compute(
      timestamp: point.timestamp,
      tBadgeC: tBadge,
      relativeHumidityPercent: rh,
      environmentState: envState,
      weather: weather,
      fSun: fSun,
      calibration: calibration,
      hasGpsFix: hasGpsFix,
      calibrationStore: _calibrationStore,
      pmvClothingInsulation: _pmvClothing(),
      cUrban: _cUrban(),
    );

    _previousTBadgeC = tBadge;
    _previousTimestamp = point.timestamp;

    return ThermalComfortSample(
      timestamp: point.timestamp,
      reading: reading,
      weather: weather,
      fSun: fSun,
    );
  }
}

class ThermalComfortSample {
  const ThermalComfortSample({
    required this.timestamp,
    required this.reading,
    required this.weather,
    required this.fSun,
  });

  final DateTime timestamp;
  final ThermalComfortReading reading;
  final WeatherSnapshot? weather;
  final double fSun;
}

/// Replay thermal readings for charts; uses stored values when present.
class ThermalComfortAnalysis {
  const ThermalComfortAnalysis({required this.samples});

  final List<ThermalComfortSample> samples;

  ThermalComfortSample? get latest => samples.lastOrNull;

  bool get isEmpty => samples.isEmpty;

  static ThermalComfortAnalysis analyze({
    required List<MeasuredDataPoint> history,
  }) {
    final samples = <ThermalComfortSample>[];
    for (final point in history) {
      final thermal = point.thermal;
      if (thermal == null) continue;
      samples.add(
        ThermalComfortSample(
          timestamp: point.timestamp,
          reading: thermal,
          weather: point.weather,
          fSun: thermal.fSun ?? 0,
        ),
      );
    }
    return ThermalComfortAnalysis(samples: samples);
  }
}
