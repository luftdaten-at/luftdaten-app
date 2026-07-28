import 'dart:math' as math;

/// ISO 7730 Fanger PMV and PPD for indoor comfort (quality grade C).
class PmvModel {
  PmvModel._();

  /// Default metabolic rate for light office activity [W/m²] (1.2 met).
  static const double defaultMetabolicWm2 = 58.15 * 1.2;

  /// Compute PMV and PPD.
  ///
  /// [paKpa] water vapour pressure in kPa (converted to Pa internally).
  /// [iclM2KPerW] clothing insulation [m²·K/W].
  static PmvResult compute({
    required double tAirC,
    required double tMrtC,
    required double airSpeedMs,
    required double relativeHumidityPercent,
    required double iclM2KPerW,
    double metabolicWm2 = defaultMetabolicWm2,
  }) {
    final ta = tAirC + 273.15;
    final tr = tMrtC + 273.15;
    final pa = _paPa(tAirC, relativeHumidityPercent);
    final m = metabolicWm2;
    final w = 0.0; // external work
    final fcl = 1 + 0.31 * iclM2KPerW;
    final hcf = 12.1 * math.sqrt(airSpeedMs.clamp(0.0, 3.0));

    var tcl = ta + (35.5 - tAirC) / (3.5 * (6.45 * iclM2KPerW + 0.1));

    for (var i = 0; i < 150; i++) {
      final hc = math.max(2.38 * math.pow(tcl - ta, 0.25), hcf);
      final tclNew = 35.7 -
          0.028 * (m - w) -
          iclM2KPerW *
              (3.96e-8 * fcl * (math.pow(tcl, 4) - math.pow(tr, 4)) +
                  fcl * hc * (tcl - ta));
      if ((tclNew - tcl).abs() < 0.00015) {
        tcl = tclNew;
        break;
      }
      tcl = tclNew;
    }

    final hc = math.max(2.38 * math.pow(tcl - ta, 0.25), hcf);
    final hl1 = 3.05e-3 * (5733 - 6.99 * m - pa);
    final hl2 = 0.42 * (m - w - 58.15);
    final hl3 = 1.7e-5 * m * (5867 - pa);
    final hl4 = 0.0014 * m * (34 - tAirC);
    final hl5 = 3.96e-8 * fcl * (math.pow(tcl, 4) - math.pow(tr, 4));
    final hl6 = fcl * hc * (tcl - ta);

    final ts = 0.303 * math.exp(-0.036 * m) + 0.028;
    final pmv = ts * (m - w - hl1 - hl2 - hl3 - hl4 - hl5 - hl6);
    final ppd = 100 - 95 * math.exp(-0.03353 * pmv * pmv - 0.2179 * pmv);

    return PmvResult(
      pmv: pmv,
      ppd: ppd.clamp(0, 100),
      tClothingC: tcl - 273.15,
    );
  }

  static double _paPa(double tAirC, double rh) {
    final es = 6.112 * math.exp(17.62 * tAirC / (243.12 + tAirC));
    return rh / 100 * es * 100; // hPa → Pa
  }
}

class PmvResult {
  const PmvResult({
    required this.pmv,
    required this.ppd,
    required this.tClothingC,
  });

  final double pmv;
  final double ppd;
  final double tClothingC;
}
