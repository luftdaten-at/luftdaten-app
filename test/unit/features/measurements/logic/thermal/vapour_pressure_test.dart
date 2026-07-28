import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/vapour_pressure.dart';

void main() {
  test('returns kPa not hPa', () {
    final pa = VapourPressure.kpa(30, 50);
    expect(pa, closeTo(2.12, 0.05));
    expect(pa, lessThan(3.0));
  });

  test('saturation at 30 C RH 50%', () {
    expect(VapourPressure.saturationHpa(30), closeTo(42.4, 0.5));
  });
}
