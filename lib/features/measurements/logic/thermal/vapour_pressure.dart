import 'dart:math' as math;

/// Water vapour pressure from air temperature and relative humidity.
///
/// Magnus formula over water (WMO coefficients). Returns **kPa** — the UTCI
/// polynomial expects kPa, while Magnus delivers hPa, hence the `/10`.
class VapourPressure {
  VapourPressure._();

  /// Maximum valid vapour pressure for the UTCI polynomial [kPa].
  static const double utciMaxKpa = 5.0;

  /// Saturation vapour pressure over water [hPa].
  static double saturationHpa(double tAirC) =>
      6.112 * math.exp(17.62 * tAirC / (243.12 + tAirC));

  /// Actual vapour pressure [kPa].
  static double kpa(double tAirC, double relativeHumidityPercent) =>
      relativeHumidityPercent / 100.0 * saturationHpa(tAirC) / 10.0;
}
