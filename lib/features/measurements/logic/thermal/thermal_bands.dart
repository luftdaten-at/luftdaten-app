import 'package:flutter/material.dart';

/// UTCI thermal stress bands (section 7.1).
enum UtciStressBand {
  extremeHeat,
  veryStrongHeat,
  strongHeat,
  moderateHeat,
  noStress,
  slightCold,
  moderateCold,
  strongCold,
  veryStrongCold,
  extremeCold;

  static UtciStressBand fromUtci(double utciC) {
    if (utciC > 46) return extremeHeat;
    if (utciC > 38) return veryStrongHeat;
    if (utciC > 32) return strongHeat;
    if (utciC > 26) return moderateHeat;
    if (utciC > 9) return noStress;
    if (utciC > 0) return slightCold;
    if (utciC > -13) return moderateCold;
    if (utciC > -27) return strongCold;
    if (utciC > -40) return veryStrongCold;
    return extremeCold;
  }

  String get labelKey => switch (this) {
        extremeHeat => 'Extreme Hitzebelastung',
        veryStrongHeat => 'Sehr starke Hitzebelastung',
        strongHeat => 'Starke Hitzebelastung',
        moderateHeat => 'Mäßige Hitzebelastung',
        noStress => 'Keine thermische Belastung',
        slightCold => 'Leichte Kältebelastung',
        moderateCold => 'Mäßige Kältebelastung',
        strongCold => 'Starke Kältebelastung',
        veryStrongCold => 'Sehr starke Kältebelastung',
        extremeCold => 'Extreme Kältebelastung',
      };

  Color get color => switch (this) {
        extremeHeat => const Color(0xFFB71C1C),
        veryStrongHeat => const Color(0xFFD32F2F),
        strongHeat => const Color(0xFFE65100),
        moderateHeat => const Color(0xFFF9A825),
        noStress => const Color(0xFF2E7D32),
        slightCold => const Color(0xFF0288D1),
        moderateCold => const Color(0xFF1565C0),
        strongCold => const Color(0xFF0D47A1),
        veryStrongCold => const Color(0xFF311B92),
        extremeCold => const Color(0xFF4A148C),
      };
}

/// PMV comfort category for indoor display.
enum PmvComfortBand {
  cold,
  slightlyCold,
  neutral,
  slightlyWarm,
  warm;

  static PmvComfortBand fromPmv(double pmv) {
    if (pmv < -1.5) return cold;
    if (pmv < -0.5) return slightlyCold;
    if (pmv <= 0.5) return neutral;
    if (pmv <= 1.5) return slightlyWarm;
    return warm;
  }

  String get labelKey => switch (this) {
        cold => 'Kalt',
        slightlyCold => 'Etwas kalt',
        neutral => 'Neutral',
        slightlyWarm => 'Etwas warm',
        warm => 'Warm',
      };

  Color get color => switch (this) {
        cold => const Color(0xFF1565C0),
        slightlyCold => const Color(0xFF0288D1),
        neutral => const Color(0xFF2E7D32),
        slightlyWarm => const Color(0xFFF9A825),
        warm => const Color(0xFFE65100),
      };
}

/// Quality grade of the comfort tile (section 8).
enum ThermalComfortQuality {
  /// Outdoor, fresh weather, calibrated body offset, f_sun determined.
  a,

  /// Outdoor but degraded inputs.
  b,

  /// Indoor — PMV/PPD instead of UTCI.
  c,

  /// Unknown context or out-of-range inputs.
  d;
}

/// Which input drives UTCI uncertainty most strongly.
enum ThermalComfortDriver {
  sun,
  wind,
  humidity,
  temperature,
  none;
}
