import 'dart:async';
import 'dart:math';

import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/map/logic/device_heading_stream.dart';

OrientationEvent _orientationEvent(double x, double y, double z, double w) =>
    OrientationEvent(
      quaternion: Quaternion(x, y, z, w).normalize(),
      accuracy: -1,
      timestamp: 0,
    );

void main() {
  group('deviceHeadingStream', () {
    test('maps sensor azimuth to LocationMarkerHeading.heading', () async {
      final north = _orientationEvent(0, 0, 0, 1);
      final rotated = _orientationEvent(
        0.4299807,
        0.4374203,
        -0.5786997,
        0.5374818,
      );

      final controller = StreamController<OrientationEvent>();
      final headings = <double?>[];
      final sub = deviceHeadingStream(sensorStream: controller.stream).listen(
        (event) => headings.add(event?.heading),
      );

      controller
        ..add(north)
        ..add(rotated)
        ..close();

      await sub.asFuture<void>();
      await sub.cancel();

      expect(headings, hasLength(2));
      expect(headings[0], closeTo(0, 0.000001));
      expect(headings[1], closeTo(rotated.eulerAngles.azimuth, 0.000001));
    });

    test('uses default accuracy when sensor accuracy is unavailable', () async {
      final controller = StreamController<OrientationEvent>();
      LocationMarkerHeading? heading;
      final sub = deviceHeadingStream(sensorStream: controller.stream).listen(
        (event) => heading = event,
      );

      controller.add(_orientationEvent(0, 0, 0, 1));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      await controller.close();

      expect(heading, isNotNull);
      expect(heading!.accuracy, closeTo(pi * 0.3, 0.000001));
    });
  });
}
