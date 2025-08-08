import 'package:flutter/material.dart';

class GradientColor {
  final double best, good, medium, bad, worst;
  final _ColorScheme _colorScheme;

  GradientColor._({
    required this.best,
    required this.good,
    required this.medium,
    required this.bad,
    required this.worst,
    required _ColorScheme colorScheme,
  }) : _colorScheme = colorScheme;

  GradientColor.pm1()
      : best = 0,
        good = 5,
        medium = 10,
        bad = 20,
        worst = 40,
        _colorScheme = _ColorScheme.greenToRed;

  GradientColor.pm25()
      : best = 0,
        good = 5,
        medium = 15,
        bad = 25,
        worst = 60,
        _colorScheme = _ColorScheme.greenToRed;

  GradientColor.pm4()
      : best = 0,
        good = 10,
        medium = 20,
        bad = 35,
        worst = 60,
        _colorScheme = _ColorScheme.greenToRed;

  GradientColor.pm10()
      : best = 0,
        good = 15,
        medium = 45,
        bad = 80,
        worst = 120,
        _colorScheme = _ColorScheme.greenToRed;

  GradientColor.temperature()
      : best = 15,
        good = 20,
        medium = 25,
        bad = 30,
        worst = 35,
        _colorScheme = _ColorScheme.blueToRed;

  GradientColor.humidity()
      : best = 0,
        good = 40,
        medium = 60,
        bad = 80,
        worst = 100,
        _colorScheme = _ColorScheme.lightBlueToDarkBlue;

  /// These numbers are somewhat arbitrary, verify in real use
  GradientColor.voc()
      : best = 70,
        good = 100,
        medium = 100,
        bad = 150,
        worst = 300,
        _colorScheme = _ColorScheme.greenToRed;

  /// These numbers are somewhat arbitrary, verify in real use
  GradientColor.nox()
      : best = 70,
        good = 100,
        medium = 100,
        bad = 150,
        worst = 300,
        _colorScheme = _ColorScheme.greenToRed;

  /// This really isn't a good vs. bad thing...
  GradientColor.pressure()
      : best = 1000,
        good = 1010,
        medium = 1020,
        bad = 1030,
        worst = 1040,
        _colorScheme = _ColorScheme.blueToRed;

  // TODO verify bounds
  GradientColor.co2()
      : best = 0,
        good = 400,
        medium = 800,
        bad = 1200,
        worst = 2000,
        _colorScheme = _ColorScheme.greenToRed;

  // TODO verify bounds
  GradientColor.o3()
      : best = 0,
        good = 5,
        medium = 20,
        bad = 40,
        worst = 60,
        _colorScheme = _ColorScheme.greenToRed;

  // TODO verify bounds
  GradientColor.aqi()
      : best = 0,
        good = 50,
        medium = 100,
        bad = 150,
        worst = 200,
        _colorScheme = _ColorScheme.greenToRed;

  // TODO verify bounds
  GradientColor.gasResistance()
      : best = 0,
        good = 5000,
        medium = 10000,
        bad = 20000,
        worst = 30000,
        _colorScheme = _ColorScheme.greenToRed;

  // TODO verify bounds
  GradientColor.totalVoc()
      : best = 0,
        good = 10,
        medium = 20,
        bad = 30,
        worst = 40,
        _colorScheme = _ColorScheme.greenToRed;

  final List<HSVColor> colorStepsGreenToRed = const [
    HSVColor.fromAHSV(1, 115, 0.8, 0.8), // Green
    HSVColor.fromAHSV(1, 115, 0.8, 0.8), // Same shade of green
    HSVColor.fromAHSV(1, 60, 0.87, 0.95), // Yellow (was 0.8, 0.63)
    HSVColor.fromAHSV(1, 0, 0.87, 0.8), // Red
    HSVColor.fromAHSV(1, 0, 0.87, 0.4), // Dark red
  ];

  final List<HSVColor> colorStepsBlueToRed = [
    HSVColor.fromColor(const Color(0xff0c04db)), // Dark blue
    HSVColor.fromColor(const Color(0xff00a2ff)), // Lighter blue
    HSVColor.fromColor(const Color(0xffadab02)), // Dark blue
    HSVColor.fromColor(const Color(0xffff7700)), // Orange
    HSVColor.fromColor(const Color(0xffc40000)), // Dark red
  ];

  final List<HSVColor> colorStepsLightBlueToDarkBlue = const [
    HSVColor.fromAHSV(1, 196, 0.53, 1), // Whiteish blue
    HSVColor.fromAHSV(1, 209, 0.71, 1), //
    HSVColor.fromAHSV(1, 227, 0.71, 1), //
    HSVColor.fromAHSV(1, 227, 0.83, 0.92), //
    HSVColor.fromAHSV(1, 227, 1, 0.7), // Deep dark blue
  ];

  Color getColor(double value) {
    if (value < best) return forColorScheme(_colorScheme)[0].toColor();
    if (value < good) {
      return interpolate(
          forColorScheme(_colorScheme)[0], forColorScheme(_colorScheme)[1], 1 - (good - value) / (good - best));
    }
    if (value < medium) {
      return interpolate(
          forColorScheme(_colorScheme)[1], forColorScheme(_colorScheme)[2], 1 - (medium - value) / (medium - good));
    }
    if (value < bad) {
      return interpolate(
          forColorScheme(_colorScheme)[2], forColorScheme(_colorScheme)[3], 1 - (bad - value) / (bad - medium));
    }
    if (value < worst) {
      return interpolate(
          forColorScheme(_colorScheme)[3], forColorScheme(_colorScheme)[4], 1 - (worst - value) / (worst - bad));
    }
    return forColorScheme(_colorScheme)[4].toColor();
  }

  Color interpolate(HSVColor a, HSVColor b, double frac) {
    return HSVColor.fromAHSV(
      1,
      a.hue + (b.hue - a.hue) * frac,
      a.saturation + (b.saturation - a.saturation) * frac,
      a.value + (b.value - a.value) * frac,
    ).toColor();
  }

  List<HSVColor> forColorScheme(_ColorScheme colorScheme) {
    switch (colorScheme) {
      case _ColorScheme.greenToRed:
        return colorStepsGreenToRed;
      case _ColorScheme.blueToRed:
        return colorStepsBlueToRed;
      case _ColorScheme.lightBlueToDarkBlue:
        return colorStepsLightBlueToDarkBlue;
    }
  }
}

enum _ColorScheme {
  greenToRed,
  blueToRed,
  lightBlueToDarkBlue,
}
