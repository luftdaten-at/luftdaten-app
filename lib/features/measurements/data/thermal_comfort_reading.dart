import 'package:luftdaten.at/features/measurements/logic/thermal/thermal_bands.dart';

/// Computed thermal comfort for one measurement point.
class ThermalComfortReading {
  const ThermalComfortReading({
    required this.model,
    required this.quality,
    this.utciC,
    this.tMrtC,
    this.pmv,
    this.ppd,
    this.fSun,
    this.v10Ms,
    this.tAirC,
    this.driver = ThermalComfortDriver.none,
    this.clampFlags = const [],
    this.computedAt,
  });

  /// `utci` outdoors, `pmv` indoors.
  final String model;

  final ThermalComfortQuality quality;
  final double? utciC;
  final double? tMrtC;
  final double? pmv;
  final double? ppd;
  final double? fSun;
  final double? v10Ms;
  final double? tAirC;
  final ThermalComfortDriver driver;
  final List<String> clampFlags;
  final DateTime? computedAt;

  UtciStressBand? get utciBand =>
      utciC != null ? UtciStressBand.fromUtci(utciC!) : null;

  PmvComfortBand? get pmvBand => pmv != null ? PmvComfortBand.fromPmv(pmv!) : null;

  Map<String, dynamic> toJson() => {
        'model': model,
        'quality': quality.name,
        if (utciC != null) 'utci': utciC,
        if (tMrtC != null) 't_mrt': tMrtC,
        if (pmv != null) 'pmv': pmv,
        if (ppd != null) 'ppd': ppd,
        if (fSun != null) 'f_sun': fSun,
        if (v10Ms != null) 'v10': v10Ms,
        if (tAirC != null) 't_a': tAirC,
        if (driver != ThermalComfortDriver.none) 'driver': driver.name,
        if (clampFlags.isNotEmpty) 'flags': clampFlags,
        if (computedAt != null) 'computed_at': computedAt!.toUtc().toIso8601String(),
      };

  factory ThermalComfortReading.fromJson(Map<String, dynamic> json) {
    final flags =
        (json['flags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    return ThermalComfortReading(
      model: json['model'] as String? ?? 'unknown',
      quality: _qualityFrom(json['quality'] as String?),
      utciC: (json['utci'] as num?)?.toDouble(),
      tMrtC: (json['t_mrt'] as num?)?.toDouble(),
      pmv: (json['pmv'] as num?)?.toDouble(),
      ppd: (json['ppd'] as num?)?.toDouble(),
      fSun: (json['f_sun'] as num?)?.toDouble(),
      v10Ms: (json['v10'] as num?)?.toDouble(),
      tAirC: (json['t_a'] as num?)?.toDouble(),
      driver: ThermalComfortDriver.values
              .where((e) => e.name == json['driver'])
              .firstOrNull ??
          ThermalComfortDriver.none,
      clampFlags: flags,
      computedAt: json['computed_at'] != null
          ? DateTime.parse(json['computed_at'] as String)
          : null,
    );
  }

  static ThermalComfortQuality _qualityFrom(String? name) =>
      ThermalComfortQuality.values.where((e) => e.name == name).firstOrNull ??
      ThermalComfortQuality.d;
}
