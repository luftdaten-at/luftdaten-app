import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/mean_radiant_temperature.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/vapour_pressure.dart';

void main() {
  group('MeanRadiantTemperature section 5.2', () {
    final pa = VapourPressure.kpa(30, 50);

    test('full sun column matches table within 0.5 K', () {
      final r = MeanRadiantTemperature.compute(
        tAirC: 30,
        paKpa: pa,
        elevationDeg: 60,
        directNormalWm2: 900,
        diffuseHorizontalWm2: 70,
        globalHorizontalWm2: 850,
        fSun: 1.0,
        cloudFraction: 0,
      );
      expect(r.kAbs, closeTo(277, 1));
      expect(r.lAbs, closeTo(486, 1));
      expect(r.sStr, closeTo(665, 2));
      expect(r.tGrdC, closeTo(47.0, 0.5));
      expect(r.tMrtC, closeTo(58.5, 0.5));
    });

    test('shade column matches table within 0.5 K', () {
      final r = MeanRadiantTemperature.compute(
        tAirC: 30,
        paKpa: pa,
        elevationDeg: 60,
        directNormalWm2: 900,
        diffuseHorizontalWm2: 150,
        globalHorizontalWm2: 150,
        fSun: 0.0,
        cloudFraction: 0,
      );
      expect(r.kAbs, closeTo(90, 1));
      expect(r.lAbs, closeTo(440, 2));
      expect(r.sStr, closeTo(489, 2));
      expect(r.tGrdC, closeTo(33.0, 0.5));
      expect(r.tMrtC, closeTo(34.0, 0.5));
    });
  });
}
