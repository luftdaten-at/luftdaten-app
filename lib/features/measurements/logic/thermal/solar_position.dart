import 'dart:math' as math;

/// Solar position from the PSA algorithm (Blanco-Muriel et al.).
///
/// Accuracy ~0.01° — sufficient for mean radiant temperature modelling.
class SolarPosition {
  const SolarPosition({
    required this.elevationDeg,
    required this.azimuthDeg,
  });

  /// Sun elevation above horizon [°]. Negative at night.
  final double elevationDeg;

  /// Sun azimuth from north, clockwise [°].
  final double azimuthDeg;

  /// Compute solar position for [whenUtc] at [latitudeDeg], [longitudeDeg].
  static SolarPosition compute({
    required DateTime whenUtc,
    required double latitudeDeg,
    required double longitudeDeg,
  }) {
    final jd = _julianDay(whenUtc);
    final d = jd - 2451545.0;

    final g = _rad(357.529 + 0.98560028 * d);
    final q = _rad(280.459 + 0.98564736 * d);
    final l = _rad((q + _deg(g) + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g)) % 360);

    final e = _rad(23.439 - 0.00000036 * d);
    final ra = math.atan2(math.cos(e) * math.sin(l), math.cos(l));
    final decl = math.asin(math.sin(e) * math.sin(l));

    final gmst = _rad((280.46061837 + 360.98564736629 * (jd - 2451545) + longitudeDeg) % 360);
    final ha = gmst - ra;

    final lat = _rad(latitudeDeg);
    final sinElev = math.sin(lat) * math.sin(decl) +
        math.cos(lat) * math.cos(decl) * math.cos(ha);
    final elev = math.asin(sinElev.clamp(-1.0, 1.0));

    final az = math.atan2(
      math.sin(ha),
      math.cos(ha) * math.sin(lat) - math.tan(decl) * math.cos(lat),
    );

    return SolarPosition(
      elevationDeg: _deg(elev),
      azimuthDeg: (_deg(az) + 360) % 360,
    );
  }

  static double _julianDay(DateTime utc) {
    final y = utc.year;
    final m = utc.month;
    final d = utc.day +
        (utc.hour + utc.minute / 60 + utc.second / 3600 + utc.millisecond / 3600000) /
            24;
    var yy = y;
    var mm = m;
    if (mm <= 2) {
      yy -= 1;
      mm += 12;
    }
    final a = (yy / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (yy + 4716)).floor() +
        (30.6001 * (mm + 1)).floor() +
        d +
        b -
        1524.5;
  }

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
}

/// Fanger projected area factor for a standing person.
double projectedAreaFactor(double elevationDeg) {
  if (elevationDeg <= 0) return 0;
  return 0.308 *
      math.cos(_rad(elevationDeg * (0.998 - elevationDeg * elevationDeg / 50000)));
}

double _rad(double deg) => deg * math.pi / 180;
