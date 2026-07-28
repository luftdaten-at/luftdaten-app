import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/utci_polynomial.dart';

void main() {
  test('matches reference fixture within 0.01 K', () {
    final file = File('test/fixtures/utci_reference.csv');
    final lines = file.readAsLinesSync().skip(1);
    for (final line in lines) {
      final parts = line.split(',');
      final tdb = double.parse(parts[0]);
      final v = double.parse(parts[1]);
      final dtr = double.parse(parts[2]);
      final pa = double.parse(parts[3]);
      final expected = double.parse(parts[4]);
      final actual = utciPolynomial(tdb, v, dtr, pa);
      expect(actual, closeTo(expected, 0.01), reason: line);
    }
  });

  test('known anchor points from validation', () {
    expect(utciPolynomial(30, 1.0, 28.5, 2.12), closeTo(37.545548, 1e-4));
    expect(utciPolynomial(0, 5.0, 0, 0.5), closeTo(-13.988977, 1e-4));
  });
}
