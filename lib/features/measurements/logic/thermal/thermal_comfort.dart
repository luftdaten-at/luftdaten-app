import 'package:luftdaten.at/features/measurements/data/environment_context_reading.dart';
import 'package:luftdaten.at/features/measurements/data/thermal_comfort_reading.dart';
import 'package:luftdaten.at/features/measurements/logic/environment_context.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/body_heat_calibration.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/mean_radiant_temperature.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/pmv.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/solar_position.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_bands.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/utci_polynomial.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/vapour_pressure.dart';
import 'package:luftdaten.at/features/weather/data/weather_snapshot.dart';

/// Computes UTCI outdoors and PMV/PPD indoors from badge + weather inputs.
class ThermalComfortCalculator {
  ThermalComfortCalculator._();

  static const fallbackWindMs = 1.0;
  static const freshWeatherLimit = Duration(minutes: 30);

  static ThermalComfortReading compute({
    required DateTime timestamp,
    required double tBadgeC,
    required double relativeHumidityPercent,
    required EnvironmentContextState environmentState,
    required WeatherSnapshot? weather,
    required double fSun,
    required BodyHeatCalibrationResult calibration,
    required bool hasGpsFix,
    BodyHeatCalibrationStore? calibrationStore,
    double pmvClothingInsulation = 0.5,
    double cUrban = 0.5,
  }) {
    final now = timestamp;

    if (environmentState == EnvironmentContextState.indoor ||
        environmentState == EnvironmentContextState.indoorWindow) {
      return _indoor(
        tAirC: tBadgeC,
        relativeHumidityPercent: relativeHumidityPercent,
        computedAt: now,
        pmvClothingInsulation: pmvClothingInsulation,
      );
    }

    if (environmentState == EnvironmentContextState.unknown || weather == null) {
      return ThermalComfortReading(
        model: 'none',
        quality: ThermalComfortQuality.d,
        computedAt: now,
      );
    }

    final weatherAge = now.difference(weather.observedAt);
    final rh = weather.rh2mPercent ?? relativeHumidityPercent;
    final cal = calibration;
    final gH = weather.globalHorizontalWm2 ?? 0.0;
    final tAir = calibrationStore?.correctedAirTemp(
          tBadgeC: tBadgeC,
          deltaK: cal.deltaK,
          fSun: fSun,
          globalHorizontalWm2: gH,
        ) ??
        tBadgeC;

    var quality = ThermalComfortQuality.a;
    if (!hasGpsFix ||
        weatherAge > freshWeatherLimit ||
        !cal.isCalibrated ||
        weather.v10Source == 'fallback') {
      quality = ThermalComfortQuality.b;
    }

    final pa = VapourPressure.kpa(tAir, rh);
    final v10Raw = weather.v10Ms ?? fallbackWindMs;
    final v10 = _urbanWind(v10Raw, cUrban);

    final lat = weather.latitude;
    final lon = weather.longitude;
    final solar = SolarPosition.compute(
      whenUtc: timestamp.toUtc(),
      latitudeDeg: lat,
      longitudeDeg: lon,
    );

    double tMrt;
    if (quality == ThermalComfortQuality.b && !weather.hasRadiation) {
      tMrt = tAir;
      quality = ThermalComfortQuality.b;
    } else if (weather.hasRadiation) {
      tMrt = MeanRadiantTemperature.compute(
        tAirC: tAir,
        paKpa: pa,
        elevationDeg: solar.elevationDeg,
        directNormalWm2: weather.directNormalWm2!,
        diffuseHorizontalWm2: weather.diffuseHorizontalWm2!,
        globalHorizontalWm2: gH,
        fSun: fSun,
        cloudFraction: weather.cloudFraction ?? 0,
      ).tMrtC;
    } else {
      tMrt = tAir;
      quality = ThermalComfortQuality.b;
    }

    final flags = <String>[];
    var tAirC = tAir;
    var tMrtUse = tMrt;
    var vUse = v10;
    var paUse = pa;

    if (tAirC < -50 || tAirC > 50) {
      flags.add('t_a');
      tAirC = tAirC.clamp(-50.0, 50.0);
    }
    final deltaTr = tMrtUse - tAirC;
    if (deltaTr < -30 || deltaTr > 70) {
      flags.add('t_mrt');
      tMrtUse = tAirC + deltaTr.clamp(-30.0, 70.0);
    }
    if (vUse < 0.5 || vUse > 17) {
      flags.add('v10');
      vUse = vUse.clamp(0.5, 17.0);
    }
    if (paUse > VapourPressure.utciMaxKpa) {
      flags.add('p_a');
      paUse = VapourPressure.utciMaxKpa;
    }
    if (flags.isNotEmpty) {
      quality = ThermalComfortQuality.d;
    }

    final utci = utciPolynomial(tAirC, vUse, tMrtUse - tAirC, paUse);
    final driver = _dominantDriver(
      tAirC: tAirC,
      tMrtC: tMrtUse,
      v10: vUse,
      paKpa: paUse,
      baseUtci: utci,
    );

    return ThermalComfortReading(
      model: 'utci',
      quality: quality,
      utciC: utci,
      tMrtC: tMrtUse,
      pmv: null,
      ppd: null,
      fSun: fSun,
      v10Ms: vUse,
      tAirC: tAirC,
      driver: driver,
      clampFlags: flags,
      computedAt: now,
    );
  }

  static ThermalComfortReading _indoor({
    required double tAirC,
    required double relativeHumidityPercent,
    required DateTime computedAt,
    required double pmvClothingInsulation,
  }) {
    final pmv = PmvModel.compute(
      tAirC: tAirC,
      tMrtC: tAirC,
      airSpeedMs: 0.1,
      relativeHumidityPercent: relativeHumidityPercent,
      iclM2KPerW: pmvClothingInsulation,
    );
    return ThermalComfortReading(
      model: 'pmv',
      quality: ThermalComfortQuality.c,
      pmv: pmv.pmv,
      ppd: pmv.ppd,
      tAirC: tAirC,
      computedAt: computedAt,
    );
  }

  static double _urbanWind(double v10, double cUrban) {
    final corrected = v10 * cUrban;
    return corrected < 0.5 ? 0.5 : corrected;
  }

  static ThermalComfortDriver _dominantDriver({
    required double tAirC,
    required double tMrtC,
    required double v10,
    required double paKpa,
    required double baseUtci,
  }) {
    final deltaTr = tMrtC - tAirC;
    final shifts = <ThermalComfortDriver, double>{
      ThermalComfortDriver.temperature: (utciPolynomial(tAirC + 2, v10, deltaTr, paKpa) -
              baseUtci)
          .abs(),
      ThermalComfortDriver.sun: (utciPolynomial(tAirC, v10, deltaTr + 5, paKpa) - baseUtci)
          .abs(),
      ThermalComfortDriver.wind: (utciPolynomial(tAirC, v10 + 1, deltaTr, paKpa) - baseUtci)
          .abs(),
      ThermalComfortDriver.humidity:
          (utciPolynomial(tAirC, v10, deltaTr, paKpa + 0.2) - baseUtci).abs(),
    };
    var best = ThermalComfortDriver.none;
    var maxShift = 0.0;
    for (final entry in shifts.entries) {
      if (entry.value > maxShift) {
        maxShift = entry.value;
        best = entry.key;
      }
    }
    return maxShift > 0.3 ? best : ThermalComfortDriver.none;
  }
}
