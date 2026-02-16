import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/utils/gradient_color.dart';

void main() {
  group('GradientColor.getColor', () {
    test('pm25: value below best returns first color', () {
      final gc = GradientColor.pm25();
      final c = gc.getColor(-1);
      expect(c, isA<Color>());
    });

    test('pm25: value at good returns second tier', () {
      final gc = GradientColor.pm25();
      final c = gc.getColor(5);
      expect(c, isA<Color>());
    });

    test('pm25: value above worst returns last color', () {
      final gc = GradientColor.pm25();
      final c = gc.getColor(100);
      expect(c, isA<Color>());
    });

    test('temperature: uses blueToRed scheme', () {
      final gc = GradientColor.temperature();
      final low = gc.getColor(10);
      final high = gc.getColor(35);
      expect(low, isA<Color>());
      expect(high, isA<Color>());
    });
  });
}
