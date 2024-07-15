import 'package:flutter_map/flutter_map.dart';

class ValueMarker<T> extends Marker {
  const ValueMarker({required super.point, required super.child, required this.value, super.width, super.height});

  final T? value;
}
