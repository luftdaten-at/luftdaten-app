/*
   Copyright (C) 2023 Thomas Ogrisegg for luftdaten.at

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'dart:collection';

class Location {
  double lat;
  double lon;
  double? height;

  Location(this.lat, this.lon, this.height);

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      (json['lat'] as num).toDouble(),
      (json['lon'] as num).toDouble(),
      json['height'] != null ? (json['height'] as num).toDouble() : null,
    );
  }
}

class Values {
  int dimension;
  double? value;

  Values(this.dimension, this.value);

  factory Values.fromJson(Map<String, dynamic> json) {
    return Values(
      json['dimension'] as int,
      (json['value'] as num?)?.toDouble(),
    );
  }
}

class Measurement {
  Location location;
  List<Values> values;
  String deviceId;
  DateTime? time;

  Measurement(this.location, this.values, this.deviceId, this.time);

  factory Measurement.fromJson(Map<String, dynamic> jsonData) {
    return Measurement(
      Location.fromJson(jsonData['location'] as Map<String, dynamic>),
      (jsonData['values'] as List)
          .map((item) => Values.fromJson(item as Map<String, dynamic>))
          .toList(),
      jsonData['device'] as String,
      DateTime.tryParse(jsonData['time_measured']?.toString() ?? ''),
    );
  }

  double? get_valueByDimension(int dimension) {
    return values.where((val) => val.dimension == dimension).firstOrNull?.value;
  }
}
