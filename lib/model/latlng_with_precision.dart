import 'package:latlong2/latlong.dart';

class LatLngWithPrecision extends LatLng {
  final double? precision;

  LatLngWithPrecision(super.latitude, super.longitude, this.precision);

  LatLngWithPrecision.from(LatLng latLng, this.precision)
      : super(latLng.latitude, latLng.longitude);

  @override
  String toString() {
    return 'LatLngWithPrecision{latitude: $latitude, longitude: $longitude, precision: $precision}';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'coordinates': [longitude, latitude],
      if (precision != null) 'precision': precision,
    };
  }

  LatLngWithPrecision.fromJson(Map<dynamic, dynamic> json)
      : precision = json['precision'],
        super(json['coordinates'][1], json['coordinates'][0]);
}

extension AsLatLngWithPrecision on LatLng {
  LatLngWithPrecision get withPrecision {
    if(this is LatLngWithPrecision) {
      return this as LatLngWithPrecision;
    }
    return LatLngWithPrecision.from(this, null);
  }
}