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
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/app/device_info.dart';
import 'package:luftdaten.at/core/domain/dimensions.dart';
import 'package:luftdaten.at/features/measurements/data/measurement.dart';


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
  /// Bulk current values for map markers (CSV: sid,latitude,longitude,pm1,pm25,pm10).
  /// The historical bulk URL without `station_ids` returns HTTP 422; use current/all instead.
  static final String _mapStationsCsvUrl =
      'https://api.luftdaten.at/v1/station/current/all';

  List<Measurement> allItems = [];
  DateTime? _lastfetch;

  void fetch() async {
    if (_lastfetch == null ||
        DateTime.now().difference(_lastfetch!).inSeconds > 300 ||
        (allItems.isEmpty && DateTime.now().difference(_lastfetch!).inSeconds > 30)) {
      await _fetch();
    }
    notifyListeners();
  }

  Future<void> _fetch() async {
    allItems = [];
    final Response resp =
        await http.get(Uri.parse(_mapStationsCsvUrl), headers: httpHeaders);
    if (resp.statusCode != 200) {
      logger.d('MapHttpProvider fetch failed with status code: ${resp.statusCode}');
      return;
    }

    final lines =
        resp.body.split(RegExp(r'\r?\n')).where((l) => l.isNotEmpty).toList();
    if (lines.length < 2) {
      logger.d('MapHttpProvider: empty CSV body');
      return;
    }

    for (final line in lines.skip(1)) {
      final parts = line.split(',');
      if (parts.length < 6) continue;
      final sid = parts[0].trim();
      final lat = double.tryParse(parts[1].trim());
      final lon = double.tryParse(parts[2].trim());
      if (lat == null || lon == null) continue;

      final pm1 = _parseCsvDouble(parts[3]);
      final pm25 = _parseCsvDouble(parts[4]);
      final pm10 = _parseCsvDouble(parts[5]);

      final values = <Values>[
        Values(Dimension.PM1_0, pm1),
        Values(Dimension.PM2_5, pm25),
        Values(Dimension.PM10_0, pm10),
      ];

      allItems.add(Measurement(Location(lat, lon, null), values, sid, null));
    }

    _lastfetch = DateTime.now();
    logger.d('MapHttpProvider: loaded ${allItems.length} stations from CSV');
  }

  /// API uses the literal string `None` for missing CSV cells.
  static double? _parseCsvDouble(String raw) {
    final t = raw.trim();
    if (t.isEmpty || t.toLowerCase() == 'none') return null;
    return double.tryParse(t);
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

  /// True once the CSV request for slice [index] has finished (success with rows, success empty, or HTTP/parse failure).
  final List<bool> sliceReady = [false, false, false];

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

  void _resetSliceState() {
    for (var i = 0; i < 3; i++) {
      items[i] = [];
      sliceReady[i] = false;
    }
  }

  Future<void> _fetch() async {
    /**
     * fetches data for last day, week and month
     */
    finished = false;
    error = false;
    _resetSliceState();
    notifyListeners();
    logger.d('SingleStationHttpProvider: Fetching data for $device_id');
    await Future.wait([
      _runSlice(0, "all"),
      _runSlice(1, "hour"),
      _runSlice(2, "hour"),
    ]);

    finished = true;
    logger.d('Fetch done for $device_id.');
    notifyListeners();
  }

  Future<void> _runSlice(int index, String precision) async {
    try {
      await _fetchForPrecision(index, precision);
    } catch (e, st) {
      logger.d('SingleStationHttpProvider: slice $index failed for $device_id: $e $st');
      error = true;
    } finally {
      sliceReady[index] = true;
      notifyListeners();
    }
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

    if (response.statusCode == 200) {
      // API CSV header (current): device,time_measured,dimension,dimension_name,value
      // Some older responses used 4 columns without dimension_name; parser supports both.
      SplayTreeMap<DateTime, Map<int, double>> data = SplayTreeMap();
      for (final line in response.body.split('\n')) {
        if (line.isEmpty || line.startsWith('device,')) continue;
        final parts = line.split(',');
        if (parts.length < 4) continue;
        try {
          final timeMeasuredString = parts[1].trim();
          final dimensionString = parts[2].trim();
          final valueString = parts[parts.length - 1].trim();

          DateTime timeMeasured = DateTime.parse(timeMeasuredString);
          int dimension = int.parse(dimensionString);
          double value = double.parse(valueString);

          data.putIfAbsent(timeMeasured, () => <int, double>{})[dimension] = value;
        } catch (_) {
          logger.d('SingleStationHttpProvider: skip malformed CSV line for $device_id');
          continue;
        }
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
    } else {
      // bad
      logger.d("Unexpected, not adding entries for $device_id ($index)");
      error = true;
    }
  }
}