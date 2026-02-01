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

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/device_info.dart';
import 'package:luftdaten.at/shared/domain/dimensions.dart';
import 'package:luftdaten.at/shared/models/measurement.dart';


class HttpProvider with ChangeNotifier {
  Map<String, String> get httpHeaders {
    String platform;
    if(Platform.isIOS) {
      platform = '${DeviceInfo.iOSPlatform} ${DeviceInfo.iOSVersion}';
    } else {
      platform = '${DeviceInfo.androidVersion}';
    }
    return {"User-Agent": "Luftdaten.at/$appVersion dart:io/${Platform.version} ($platform; ${DeviceInfo.deviceName})"};
  }
}

class DataItem {
  DataItem(this.pm1, this.pm25, this.pm10, [this.timestamp]);

  DateTime? timestamp;
  double? pm1;
  double? pm25;
  double? pm10;

  @override
  String toString() {
    return 'LDItem($timestamp, $pm1, $pm25, $pm10)';
  }
}

/*
class DataLocationItem extends DataItem {
  String device_id;
  double latitude;
  double longitude;

  DataLocationItem(this.device_id, this.latitude, this.longitude, super.pm1, super.pm25, super.pm10);
}
*/

class MapHttpProvider extends HttpProvider {
  /// for every station fetches the current values with thier location
  final String API_URL = "https://api.luftdaten.at/v1/station/historical?end=current&precision=all&output_format=json&include_location=true";
  List<Measurement> allItems = [];
  DateTime? _lastfetch;

  void fetch() async {
    if (_lastfetch == null ||
        DateTime.now().difference(_lastfetch!).inSeconds > 300 ||
        (allItems.isEmpty && DateTime.now().difference(_lastfetch!).inSeconds > 30)) {
      _lastfetch = DateTime.now();
      await _fetch();
    }
    notifyListeners();
  }

  Future<void> _fetch() async {
    // fetch in json format
    allItems = [];
    Response resp = await http.get(Uri.parse(API_URL), headers: httpHeaders);
    if(resp.statusCode == 200){
      var json = jsonDecode(resp.body);
      for(var j in json){
        allItems.add(Measurement.fromJson(j));
      }
    }else{
      logger.d("MapHttpProvider fetch failed with status code: ${resp.statusCode}");
    }
  }
}


class SingleStationHttpProvider extends HttpProvider {
  /// device_id: Device id in api.luftdaten.at format
  /// for the given station data is fetch from API_URL
  /// items contains 3 resolutions of the fetched data. See definition of items

  final String API_URL = "https://api.luftdaten.at/v1/station/historical";
  final String device_id;

  /// ([Data last day], [last week], [last month]):
  List<List<DataItem>> items = [[], [], []];
  bool finished = false;
  bool error = false;

  //SingleStationHttpProvider._(this.sid, [this.isAirStation = false]);
  SingleStationHttpProvider._(this.device_id);

  factory SingleStationHttpProvider(String device_id) {
    if (_providers[device_id] != null) {
      return _providers[device_id]!;
    } else {
      SingleStationHttpProvider provider = SingleStationHttpProvider._(device_id);
      provider._fetch();
      _providers[device_id] = provider;
      return provider;
    }
  }

  static final Map<String, SingleStationHttpProvider> _providers = {};

  Future<void> refetch() async {
    await _fetch();
  }

  Future<void> _fetch() async {
    /**
     * fetches data for last day, week and month
     */
    finished = false;
    error = false;
    notifyListeners();
    logger.d('SingleStationHttpProvider: Fetching data for $device_id');
    await _fetchForPrecision(0, "all");
    await _fetchForPrecision(1, "hour");
    await _fetchForPrecision(2, "hour");

    finished = true;
    logger.d('Fetch done for $device_id.');
    notifyListeners();
  }

  Future<void> _fetchForPrecision(int index, String precision) async {
    items[index] = [];
    // example url
    //https://api.luftdaten.at/v1/station/historical?station_ids=278SC&precision=day&output_format=json'
    DateTime start = DateTime.now().toUtc();

    if(index == 0){ // 1 day
      start = start.subtract(Duration(days: 1));
    }else if(index == 1){ // 1 week
      start = start.subtract(Duration(days: 7));
    }else if(index == 2){
      start = start.subtract(Duration(days: 30));
    }
    
    String requestUrl = "$API_URL/?station_ids=$device_id&precision=$precision&output_format=csv&start=${start.toIso8601String()}";
    Response response = await http.get(Uri.parse(requestUrl), headers: httpHeaders);

    if(response.statusCode == 200){
      // all good
      // header: device,time_measured,dimension,value
      SplayTreeMap<DateTime, Map<int, double>> data = SplayTreeMap();
      for(var line in response.body.split("\n").sublist(1)){ // sublist(1) kipp header
        if(line.isEmpty) continue;
        var [device, time_measured_string, dimension_string, value_string] = line.split(",");

        DateTime time_measured = DateTime.parse(time_measured_string);
        int dimension = int.parse(dimension_string);
        double value = double.parse(value_string);

        data.putIfAbsent(time_measured, () => <int, double>{})[dimension] = value;
      }

      for (var entry in data.entries) {
        DataItem item = DataItem(
          entry.value[Dimension.PM1_0] ?? 0,
          entry.value[Dimension.PM2_5] ?? 0,
          entry.value[Dimension.PM10_0] ?? 0,
          entry.key,
        );
        items[index].add(item);
      }
      logger.d('Added ${items[index].length} entries for $device_id ($index)');
    }else{
      // bad
      logger.d("Unexpected, not adding entries for $device_id ($index)");
      error = true;
    }
  }
}