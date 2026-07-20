import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';

/// Device heading for map location marker rotation (via [flutter_rotation_sensor]).
Stream<LocationMarkerHeading?> deviceHeadingStream({
  Stream<OrientationEvent>? sensorStream,
}) =>
    const LocationMarkerDataStreamFactory().fromRotationSensorHeadingStream(
      stream: sensorStream,
    );
