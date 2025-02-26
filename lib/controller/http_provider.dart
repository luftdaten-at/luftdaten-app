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

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/controller/device_info.dart';
import 'package:luftdaten.at/controller/news_controller.dart';
import 'package:luftdaten.at/util/day.dart';

import '../main.dart';
import '../enums.dart';
import '../model/sensor_data.dart';

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

class SCItem {
  SCItem(this.timestamp, this.sid, this.latitude, this.longitude, this.pm1, this.pm25, this.pm10);

  DateTime timestamp;
  String sid;
  double latitude;
  double longitude;
  double? pm1;
  double? pm25;
  double? pm10;
}

class SCHttpProvider extends HttpProvider {
  List<SCItem> items = [];
  List<SCItem> allItems = [];
  DateTime? _lastfetch;

  double? getSDValue(String name, SCData item) {
    for (var it in item.sensordatavalues) {
      if (it.value_type == name) return double.parse(it.value);
    }
    return null;
  }

  void extend(LatLngBounds llb, double zoom) {
    if (zoom < 10.0) return;
    double inc = (zoom - 10.0) * 0.05;
    var l1 = LatLng(llb.northWest.latitude + inc, llb.northWest.longitude - inc);
    var l2 = LatLng(llb.southEast.latitude - inc, llb.southEast.longitude + inc);
    llb.extend(l1);
    llb.extend(l2);
  }

  void fetch([LatLngBounds? llb, double? zoom]) async {
    if (_lastfetch == null ||
        DateTime.now().difference(_lastfetch!).inSeconds > 300 ||
        (allItems.isEmpty && DateTime.now().difference(_lastfetch!).inSeconds > 30)) {
      _lastfetch = DateTime.now();
      await fetchDust2();
    }
    notifyListeners();
  }

  Future<List<SCItem>> fetchDust2() async {
    String url = "https://dev.luftdaten.at/d/station/history/all";
    DateTime d1 = DateTime.now();
    var response = await http.get(Uri.parse(url), headers: httpHeaders);
    DateTime d2 = DateTime.now();
    logger.d("D2: ${d2.difference(d1).inMicroseconds}");
    logger.d("FD: Got $response from $url");
    if (response.statusCode == 200) {
      allItems = [];
      for (var line in response.body.split('\n')) {
        if (line == "") continue;
        List<String> l = line.split('\t');
        if (l.length != 6) {
          logger.e("Invalid line: $line");
          continue;
        }
        allItems.add(SCItem(d2, l[0], double.parse(l[1]), double.parse(l[2]),
            double.parse(l[3]), double.parse(l[5]), double.parse(l[4])));
      }
      logger.d("Fetched ${allItems.length} items");
      DateTime d3 = DateTime.now();
      logger.d("D3: ${d3.difference(d2).inMicroseconds}");

      if (allItems.isEmpty) logger.d("Items length == 0!");

      return allItems;
    } else {
      logger.e("Error: Got ${response.statusCode} HTTP answer");
    }
    return [];
  }

  Future<List<SCItem>> fetchDust() async {
    String url = "https://data.sensor.community/static/v2/data.dust.min.json";
    DateTime d1 = DateTime.now();

    var response = await http.get(Uri.parse(url), headers: httpHeaders);
    DateTime d2 = DateTime.now();
    if (kDebugMode) {
      print("D2: ${d2.difference(d1).inMicroseconds}");
      print("FD: Got $response from $url");
    }
    if (response.statusCode == 200) {
      allItems = [];
      final scList = jsonDecode(response.body)
          .cast<Map<String, dynamic>>()
          .map<SCData>((json) => SCData.fromJson(json))
          .toList();
      DateTime d3 = DateTime.now();
      if (kDebugMode) {
        print("D3: ${d3.difference(d2).inMicroseconds}");
      }
      for (var sc in scList) {
        allItems.add(SCItem(
            sc.timestamp,
            sc.sensor.id,
            double.parse(sc.location.latitude),
            double.parse(sc.location.longitude),
            getSDValue("P0", sc),
            getSDValue("P2", sc),
            getSDValue("P1", sc)));
      }
      DateTime d4 = DateTime.now();
      if (kDebugMode) {
        print("D4: ${d4.difference(d3).inMicroseconds}");
      }
      if (allItems.isNotEmpty) {
        if (kDebugMode) {
          print("Notifying listeners...");
        }
      } else if (kDebugMode) {
        print("Items length == 0!");
      }
      return allItems;
    } else {
      if (kDebugMode) {
        print("Error: Got ${response.statusCode} HTTP answer");
      }
    }
    return [];
  }
}

class LDItem {
  LDItem(this.timestamp, this.pm1, this.pm25, this.pm10);

  DateTime timestamp;
  double? pm1;
  double pm25;
  double pm10;

  @override
  String toString() {
    return 'LDItem($timestamp, $pm1, $pm25, $pm10)';
  }
}

class LDHttpProvider extends HttpProvider {
  /**
   * 
   */
  List<LDItem> items = [];
  bool finished = false;
  final String baseURL = "https://dev.luftdaten.at/d";
  late String pollURL = "$baseURL/station/register/poll?id=";

  Future<List<LDItem>> fetch(int sid, int backsecs) async {
    finished = false;
    items = [];
    DateTime ts = DateTime.now().subtract(Duration(seconds: backsecs));
    String url =
        "https://dev.luftdaten.at/d/station/history?sid=$sid&smooth=100&from=${ts.toLocal()}";
    if (kDebugMode) {
      print("LDFetching: $url");
    }
    Response response = await http.get(Uri.parse(url), headers: httpHeaders);
    if (response.statusCode == 200) {
      List<String> lines = response.body.split('\n');
      logger.d('HTTP response:');
      for (var line in lines) {
        logger.d(line);
        List<String> entries = line.split(';');
        if (entries.length <= 1) continue;
        double? pm1 = double.parse(entries[1]);
        if (pm1.isNaN || pm1 == 0.0) pm1 = null;
        items.add(LDItem(
          DateTime.fromMillisecondsSinceEpoch(int.parse(entries[0]) * 1000),
          pm1,
          double.parse(entries[2]),
          double.parse(entries[3]),
        ));
      }
      if (kDebugMode) {
        print("Fetched ${lines.length} entries");
      }
      finished = true;
      notifyListeners();
      return items;
    } else {
      if (kDebugMode) {
        print("Error: Got ${response.statusCode} HTTP answer");
      }
      return [];
    }
  }

  Future<dynamic> checkStation(String id) async {
    return http.get(Uri.parse(pollURL + id), headers: httpHeaders);
  }

  Future<bool> sendData(String url, String data) async {
    var response = await http.post(Uri.parse(url), headers: httpHeaders, body: data);
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print("Error: POST response: ${response.statusCode}");
      }
    }
    return response.statusCode == 200;
  }

  Future<dynamic> sendDataWithResponse(String url, String data) async {
    return http.post(Uri.parse(url), headers: httpHeaders, body: data);
  }
}

/*
class SingleStationHttpProvider extends HttpProvider {
  List<List<LDItem>> items = [[], [], []];
  bool finished = false;
  bool error = false;
  final String baseURL = "https://dev.luftdaten.at/d";
  late String pollURL = "$baseURL/station/register/poll?id=";

  final String sid;
  final bool isAirStation;

  SingleStationHttpProvider._(this.sid, [this.isAirStation = false]);

  factory SingleStationHttpProvider(String sid,
      [bool isAirStation = false, bool initialFetch = true]) {
    if (_providers[sid] != null) {
      return _providers[sid]!;
    } else {
      SingleStationHttpProvider provider = SingleStationHttpProvider._(sid, isAirStation);
      if (initialFetch) provider._fetch();
      _providers[sid] = provider;
      return provider;
    }
  }

  static final Map<String, SingleStationHttpProvider> _providers = {};

  Future<void> refetch() async {
    await _fetch();
  }

  Future<void> _fetch() async {
    finished = false;
    error = false;
    notifyListeners();
    logger.d('Fetching data for $sid (${isAirStation ? 'AirStation' : 'Sensor.Community'}) ...');
    await _fetchForPeriod(sid, 0, 60 * 60 * 24);
    await _fetchForPeriod(sid, 1, 60 * 60 * 24 * 7);
    await _fetchForPeriod(sid, 2, 60 * 60 * 24 * 30);
    finished = true;
    logger.d('Fetch done for $sid.');
    notifyListeners();
  }

  Future<void> _fetchForPeriod(String sid, int index, int backsecs) async {
    items[index] = [];
    DateTime ts = DateTime.now().subtract(Duration(seconds: backsecs));

    String url;
    if (isAirStation) {
      List<int> macBytes = hex.decode(sid);
      macBytes[macBytes.length - 1] = macBytes[macBytes.length - 1] - 1;
      List<int> chipIdBytes = macBytes.reversed.toList();
      String chipId = hex.encode(chipIdBytes);
      url =
          "https://dev.luftdaten.at/d/station/history?sid=$chipId&smooth=100&from=${ts.toLocal()}&ldstation=1";
    } else {
      url = "https://dev.luftdaten.at/d/station/history?sid=$sid&smooth=100&from=${ts.toLocal()}";
    }

    logger.d('Fetching data for $sid ($index) for past $backsecs seconds from ${ts.toLocal()} ...');
    logger.d('URL: $url');

    Response response = await http.get(Uri.parse(url), headers: httpHeaders);
    logger.d('Received HTTP ${response.statusCode}');

    if (response.statusCode == 200) {
      List<String> lines = response.body.split('\n');
      for (var line in lines) {
        List<String> entries = line.split(';');
        if (entries.length <= 1) continue;
        double? pm1 = double.parse(entries[1]);
        if (pm1.isNaN || pm1 == 0.0) pm1 = null;
        DateTime ts;
        try {
          ts = DateTime.fromMillisecondsSinceEpoch(int.parse(entries[0]) * 1000);
        } catch(_) {
          ts = DateTime.parse('${entries[0]}Z').toLocal();
        }
        items[index].add(LDItem(
          ts,
          pm1,
          double.parse(entries[2]),
          double.parse(entries[3]),
        ));
      }
      logger.d('Added ${items[index].length} entries for $sid ($index)');
    } else {
      logger.d("Unexpected, not adding entries for $sid ($index)");
      error = true;
    }
  }
}
*/

class SingleStationHttpProvider extends HttpProvider {
  /// device_id: Device id in api.luftdaten.at format
  /// for the given station data is fetch from API_URL
  /// items contains 3 resolutions of the fetched data. See definition of items

  final String API_URL = "https://api.luftdaten.at/v1/station/historical";
  final String device_id;

  /// ([Data last day], [last week], [last month]):
  List<List<LDItem>> items = [[], [], []];
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

        data.putIfAbsent(time_measured, () => {})[dimension] = value;
      }

      for(var entry in data.entries){
        LDItem item = LDItem(
          entry.key, 
          entry.value[Dimension.PM1_0.value] ?? 0, // when not present insert 0
          entry.value[Dimension.PM2_5.value] ?? 0,
          entry.value[Dimension.PM10_0.value] ?? 0,
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

class AirStationHttpProvider extends HttpProvider {
  Future<List<LDItem>> fetch(String mac, int backsecs) async {
    List<int> macBytes = hex.decode(mac);
    macBytes[macBytes.length - 1] = macBytes[macBytes.length - 1] - 1;
    List<int> chipIdBytes = macBytes.reversed.toList();
    String chipId = hex.encode(chipIdBytes);
    DateTime ts = DateTime.now().subtract(Duration(seconds: backsecs));
    String url =
        "https://dev.luftdaten.at/d/station/history?sid=$chipId&smooth=100&from=${ts.toLocal()}&ldstation=1";
    Response response = await http.get(Uri.parse(url), headers: httpHeaders);
    List<LDItem> items = [];
    if (response.statusCode == 200) {
      List<String> lines = response.body.split('\n');
      logger.d('HTTP response:');
      for (var line in lines) {
        logger.d(line);
        List<String> entries = line.split(';');
        if (entries.length <= 1) continue;
        double? pm1 = double.parse(entries[1]);
        if (pm1.isNaN || pm1 == 0.0) pm1 = null;
        items.add(LDItem(
          DateTime.parse('${entries[0]}Z').toLocal(),
          pm1,
          double.parse(entries[2]),
          double.parse(entries[3]),
        ));
      }
      if (kDebugMode) {
        print("Fetched ${lines.length} entries");
      }
      notifyListeners();
      return items;
    } else {
      if (kDebugMode) {
        print("Error: Got ${response.statusCode} HTTP answer");
      }
      return [];
    }
  }
}
