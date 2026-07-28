import 'dart:math' as math;

import 'package:luftdaten.at/features/measurements/logic/thermal/solar_position.dart';

/// Mean radiant temperature model (VDI 3787 Bl. 2 simplified).
class MeanRadiantTemperature {
  MeanRadiantTemperature._();

  static const double alphaK = 0.70;
  static const double epsP = 0.97;
  static const double sigma = 5.670374419e-8;
  static const double fSky = 0.5;
  static const double fGrd = 0.5;
  static const double rhoG = 0.20;
  static const double epsGrd = 0.95;
  static const double kGrd = 0.02;

  /// Shortwave + longwave balance → mean radiant temperature [°C].
  ///
  /// [gH] already reflects local shading; [fSun] scales direct beam on the
  /// person only. Ground temperature uses [gH] alone (table-consistent form).
  static MeanRadiantTemperatureResult compute({
    required double tAirC,
    required double paKpa,
    required double elevationDeg,
    required double directNormalWm2,
    required double diffuseHorizontalWm2,
    required double globalHorizontalWm2,
    required double fSun,
    required double cloudFraction,
  }) {
    final fP = projectedAreaFactor(elevationDeg);
    final kAbs = fP * directNormalWm2 * fSun +
        fSky * diffuseHorizontalWm2 +
        fGrd * rhoG * globalHorizontalWm2;

    final tAirK = tAirC + 273.15;
    // G_h already carries shading; do not multiply by f_sun again here.
    final tGrdC = tAirC + kGrd * globalHorizontalWm2;
    final tGrdK = tGrdC + 273.15;
    final epsSky = _skyEmissivity(paKpa, tAirC, cloudFraction);

    final lAbs = fSky * epsSky * sigma * tAirK * tAirK * tAirK * tAirK +
        fGrd * epsGrd * sigma * tGrdK * tGrdK * tGrdK * tGrdK;

    final sStr = alphaK * kAbs + epsP * lAbs;
    final tMrtK = math.pow(sStr / (epsP * sigma), 0.25).toDouble();
    final tMrtC = tMrtK - 273.15;

    return MeanRadiantTemperatureResult(
      tMrtC: tMrtC,
      kAbs: kAbs,
      lAbs: lAbs,
      sStr: sStr,
      tGrdC: tGrdC,
      epsSky: epsSky,
      fP: fP,
    );
  }

  static double _skyEmissivity(double paKpa, double tAirC, double cloudFraction) {
    final epsClear = 1.24 * math.pow(paKpa * 10.0 / (tAirC + 273.15), 1 / 7);
    return epsClear + (1 - epsClear) * cloudFraction.clamp(0.0, 1.0);
  }
}

class MeanRadiantTemperatureResult {
  const MeanRadiantTemperatureResult({
    required this.tMrtC,
    required this.kAbs,
    required this.lAbs,
    required this.sStr,
    required this.tGrdC,
    required this.epsSky,
    required this.fP,
  });

  final double tMrtC;
  final double kAbs;
  final double lAbs;
  final double sStr;
  final double tGrdC;
  final double epsSky;
  final double fP;
}
