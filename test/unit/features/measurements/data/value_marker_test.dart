import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/features/measurements/data/value_marker.dart';

void main() {
  group('ValueMarker', () {
    test('holds value and point', () {
      final point = LatLng(48.21, 16.37);
      const value = 42.5;
      final marker = ValueMarker<double>(
        point: point,
        child: const SizedBox(),
        value: value,
      );
      expect(marker.point, point);
      expect(marker.value, value);
    });

    test('value can be null', () {
      final marker = ValueMarker<String?>(
        point: LatLng(48.0, 16.0),
        child: const SizedBox(),
        value: null,
      );
      expect(marker.value, isNull);
    });
  });
}
