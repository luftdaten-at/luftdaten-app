import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/main.dart';

class Location {
  double lat;
  double lon;
  double? height;

  Location(this.lat, this.lon, this.height);

  factory Location.fromJson(Map<dynamic, dynamic> json) {
    return Location(
      json['lat'],
      json['lon'],
      json['height'],
    );
  }

  LatLng to_LatLng(){
    return LatLng(lat, lon);
  }
}

class Values {
  int dimension;
  double value;

  Values(this.dimension, this.value);

  factory Values.fromJson(Map<dynamic, dynamic> json) {
    return Values(
      json['dimension'],
      json['value'],
    );
  }
}

class Measurement {
  Location? location;
  List<Values> values;
  String deviceId;
  DateTime? time;

  Measurement(this.location, this.values, this.deviceId, this.time);

  factory Measurement.fromJson(Map<dynamic, dynamic> jsonData) {
    return Measurement(
      Location.fromJson(jsonData['location']),
      (jsonData['values'] as List).map((item) => Values.fromJson(item)).toList(),
      jsonData['device'],
      DateTime.tryParse(jsonData['time_measured']),
    );
  }

  double? get_valueByDimension(int dimension){ 
    return values.where((val) => val.dimension == dimension).firstOrNull?.value;
  }
}

class RawMeasurement {
  // the json should be in the luftdaten API format see: api.luftdaten.at/docs, endpoint /station/data
  Map<dynamic, dynamic> json;
  RawMeasurement(this.json);

  List<String> toCsv(){
    throw UnimplementedError("To CSV method is not yet implemented for raw measurement");
  }

  Measurement toMeasurement(){
    /**
     * returns a measurement base on the raw data
     * since there could be many sensors that have the same dimension we just take the mean
     */
    List<MapEntry<int, double>> groupedValues = (json["sensors"] as Map<dynamic, dynamic>)
      .values
      .expand((e) => (e['data'] as Map<int, double>).entries)
      .toList();
    
    Map<int, List<double>> avg = {};
    // group by dimension
    for(var e in groupedValues){
      avg.putIfAbsent(e.key, () => []);
      avg[e.key]!.add(e.value);
    }

    List<Values> values = [];
    for(var e in avg.entries){
      // take mean
      values.add(Values(e.key, e.value.reduce((a, b) => a + b) / e.value.length));
    }

    return Measurement(
      (json["station"] as Map<dynamic, dynamic>).containsKey("location") ? 
        Location(
          json["station"]["location"]["lat"],
          json["station"]["location"]["lon"], 
          json["station"]["location"]["height"]
      ) : null,
      values, 
      json["station"]["device"], 
      json["station"]["time"]
    );
  }
}

/*

{

   "sensors":{

      "0":{

         "data":{

            "6":31.9416,

            "7":24.0467

         },

         "type":10

      },

      "1":{

         "data":{

            "7":24.315,

            "8":103.0,

            "2":4.4,

            "3":4.6,

            "4":4.6,

            "5":4.6,

            "6":32.31

         },

         "type":1

      }

   },

   "station":{

      "time":"2025-03-12T08:15:53.000Z",

      "source":1,

      "model":1,

      "apikey":"jxwgvc8kxynptsmpbeudkxnn43otjww3",

      "firmware":"1.5.1",

      "device":"DCDA0C781991AAA",

      "battery":{

         "percentage":103.988,

         "voltage":4.215

      }

   }

}

*/