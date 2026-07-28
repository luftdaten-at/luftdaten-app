import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/data/environment_context_reading.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/body_heat_calibration.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_bands.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_comfort.dart';
import 'package:luftdaten.at/features/weather/data/weather_snapshot.dart';

void main() {
  WeatherSnapshot sampleWeather({DateTime? observedAt}) => WeatherSnapshot(
        observedAt: observedAt ?? DateTime(2026, 7, 28, 15, 30),
        fetchedAt: DateTime(2026, 7, 28, 15, 31),
        latitude: 48.21,
        longitude: 16.37,
        t2mC: 30.4,
        rh2mPercent: 24,
        v10Ms: 2.2,
        v10Source: 'tawes',
        cloudFraction: 0,
        globalHorizontalWm2: 850,
        directNormalWm2: 900,
        diffuseHorizontalWm2: 70,
        radiationSource: 'open_meteo',
      );

  test('indoor returns PMV quality C', () {
    final reading = ThermalComfortCalculator.compute(
      timestamp: DateTime(2026, 7, 28, 15, 30),
      tBadgeC: 22,
      relativeHumidityPercent: 45,
      environmentState: EnvironmentContextState.indoor,
      weather: sampleWeather(),
      fSun: 0,
      calibration: const BodyHeatCalibrationResult(
        deltaK: 2,
        sampleCount: 40,
        usingFallback: false,
      ),
      hasGpsFix: true,
    );
    expect(reading.quality, ThermalComfortQuality.c);
    expect(reading.model, 'pmv');
    expect(reading.pmv, isNotNull);
    expect(reading.utciC, isNull);
  });

  test('outdoor with fresh weather returns UTCI quality A or B', () {
    final reading = ThermalComfortCalculator.compute(
      timestamp: DateTime(2026, 7, 28, 15, 30),
      tBadgeC: 30,
      relativeHumidityPercent: 50,
      environmentState: EnvironmentContextState.outdoor,
      weather: sampleWeather(),
      fSun: 1,
      calibration: const BodyHeatCalibrationResult(
        deltaK: 2,
        sampleCount: 40,
        usingFallback: false,
      ),
      hasGpsFix: true,
    );
    expect(reading.model, 'utci');
    expect(reading.utciC, isNotNull);
    expect(reading.quality, isIn([ThermalComfortQuality.a, ThermalComfortQuality.b]));
  });

  test('unknown environment returns quality D', () {
    final reading = ThermalComfortCalculator.compute(
      timestamp: DateTime(2026, 7, 28, 15, 30),
      tBadgeC: 30,
      relativeHumidityPercent: 50,
      environmentState: EnvironmentContextState.unknown,
      weather: null,
      fSun: 0,
      calibration: const BodyHeatCalibrationResult(
        deltaK: null,
        sampleCount: 0,
        usingFallback: false,
      ),
      hasGpsFix: false,
    );
    expect(reading.quality, ThermalComfortQuality.d);
  });
}
