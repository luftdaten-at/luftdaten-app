import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/features/measurement/models/latlng_with_precision.dart';

void main() {
  group('LatLngWithPrecision', () {
    test('toJson and fromJson roundtrip', () {
      final ll = LatLngWithPrecision(48.2, 16.4, 0.01);
      final json = ll.toJson();
      final restored = LatLngWithPrecision.fromJson(json);
      expect(restored.latitude, ll.latitude);
      expect(restored.longitude, ll.longitude);
      expect(restored.precision, ll.precision);
    });

    test('from parses LatLng correctly', () {
      final latlng = LatLng(48.2, 16.4);
      final ll = LatLngWithPrecision.from(latlng, 0.005);
      expect(ll.latitude, 48.2);
      expect(ll.longitude, 16.4);
      expect(ll.precision, 0.005);
    });
  });
}
