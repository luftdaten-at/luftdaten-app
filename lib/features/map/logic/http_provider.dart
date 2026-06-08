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

  double? valueForDimension(int dimensionId) {
    switch (dimensionId) {
      case Dimension.PM1_0:
        return pm1;
      case Dimension.PM2_5:
        return pm25;
      case Dimension.PM10_0:
        return pm10;
      default:
        return null;
    }
  }

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
  /// Bulk current values for Messnetz map markers (`FeatureCollection` GeoJSON).
  /// Query filters active stations (`last_active` seconds) without calibration layers.
  static final Uri _mapStationsGeoJsonUri = Uri.https(
    'api.luftdaten.at',
    '/v1/station/current',
    <String, String>{
      'last_active': '3600',
      'output_format': 'geojson',
      'calibration_data': 'false',
    },
  );

  List<Measurement> allItems = [];
  DateTime? _lastfetch;
  bool isLoading = false;
  bool hasLoadedOnce = false;

  void fetch() async {
    if (_lastfetch == null ||
        DateTime.now().difference(_lastfetch!).inSeconds > 300 ||
        (allItems.isEmpty && DateTime.now().difference(_lastfetch!).inSeconds > 30)) {
      await _fetch();
    }
    notifyListeners();
  }

  Future<void> _fetch() async {
    isLoading = true;
    notifyListeners();
    try {
      allItems = [];
      final Response resp = await http.get(_mapStationsGeoJsonUri, headers: httpHeaders);
      if (resp.statusCode != 200) {
        logger.d('MapHttpProvider fetch failed with status code: ${resp.statusCode}');
        return;
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(resp.body);
      } catch (e, st) {
        logger.d('MapHttpProvider: JSON decode failed: $e $st');
        return;
      }

      final features = (decoded is Map<String, dynamic>) ? decoded['features'] : null;
      if (features is! List) {
        logger.d('MapHttpProvider: missing or invalid features array');
        return;
      }

      for (final Object? rawFeature in features) {
        if (rawFeature is! Map) continue;
        final feature = Map<String, dynamic>.from(rawFeature);
        final m = measurementFromStationCurrentGeoFeature(feature);
        if (m != null) allItems.add(m);
      }

      _lastfetch = DateTime.now();
      hasLoadedOnce = true;
      logger.d('MapHttpProvider: loaded ${allItems.length} stations from GeoJSON');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Parses one GeoJSON Feature from `/v1/station/current` (see API `output_format=geojson`).
  ///
  /// PM1 / PM2.5 / PM10 are taken from all `properties.sensors[*].values`; later entries overwrite
  /// earlier ones when the same dimension appears on multiple sensors.
  static Measurement? measurementFromStationCurrentGeoFeature(Map<String, dynamic> feature) {
    final geomRaw = feature['geometry'];
    if (geomRaw is! Map) return null;
    final geom = Map<String, dynamic>.from(geomRaw);
    if (geom['type'] != 'Point') return null;

    final coords = geom['coordinates'];
    if (coords is! List || coords.length < 2) return null;
    final lonNum = coords[0];
    final latNum = coords[1];
    if (lonNum is! num || latNum is! num) return null;

    final propsRaw = feature['properties'];
    if (propsRaw is! Map) return null;
    final props = Map<String, dynamic>.from(propsRaw);

    final device = props['device']?.toString();
    if (device == null || device.isEmpty) return null;

    double? stationHeight;
    final hRaw = props['height'];
    if (hRaw is num) {
      stationHeight = hRaw.toDouble();
    }

    DateTime? timeMeasured;
    final timeRaw = props['time']?.toString();
    if (timeRaw != null && timeRaw.isNotEmpty) {
      timeMeasured = DateTime.tryParse(timeRaw);
    }

    final Map<int, double> byDimension = {};
    final sensors = props['sensors'];
    if (sensors is List) {
      for (final sensor in sensors) {
        if (sensor is! Map) continue;
        final sensorMap = Map<String, dynamic>.from(sensor);
        final values = sensorMap['values'];
        if (values is! List) continue;
        for (final v in values) {
          if (v is! Map) continue;
          final entry = Map<String, dynamic>.from(v);
          final dimRaw = entry['dimension'];
          final valRaw = entry['value'];
          if (dimRaw == null || valRaw == null || valRaw is! num) continue;
          final dimension = dimRaw is int ? dimRaw : int.tryParse(dimRaw.toString());
          if (dimension == null) continue;
          final value = valRaw.toDouble();
          byDimension[dimension] = value;
        }
      }
    }

    final values = <Values>[
      Values(Dimension.PM1_0, byDimension[Dimension.PM1_0]),
      Values(Dimension.PM2_5, byDimension[Dimension.PM2_5]),
      Values(Dimension.PM10_0, byDimension[Dimension.PM10_0]),
    ];

    return Measurement(
      Location(latNum.toDouble(), lonNum.toDouble(), stationHeight),
      values,
      device,
      timeMeasured,
    );
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

  /// Hourly means for the last 24 hours (map station dialog).
  List<DataItem> hourly24h = [];

  /// True once the CSV request for slice [index] has finished (success with rows, success empty, or HTTP/parse failure).
  final List<bool> sliceReady = [false, false, false];

  bool hourly24hReady = false;
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
    hourly24hReady = false;
    hourly24h = [];
    _resetSliceState();
    notifyListeners();
    logger.d('SingleStationHttpProvider: Fetching data for $device_id');
    await Future.wait([
      _fetchHourly24hJson(),
      _runSlice(0, "all"),
      _runSlice(1, "hour"),
      _runSlice(2, "hour"),
    ]);

    finished = true;
    logger.d('Fetch done for $device_id.');
    notifyListeners();
  }

  Future<void> _fetchHourly24hJson() async {
    try {
      final now = DateTime.now().toUtc();
      final endHour = DateTime.utc(now.year, now.month, now.day, now.hour);
      final startHour = endHour.subtract(const Duration(hours: 23));
      final startIso = startHour.toIso8601String().substring(0, 16);
      final endIso = endHour.toIso8601String().substring(0, 16);
      final uri = Uri.parse(
        '$API_URL/?station_ids=$device_id&output_format=json&precision=hour&start=$startIso&end=$endIso',
      );
      final response = await http.get(uri, headers: httpHeaders);
      if (response.statusCode == 200) {
        hourly24h = parseHistoricalHourlyJson(response.body);
        logger.d('SingleStationHttpProvider: loaded ${hourly24h.length} hourly rows for $device_id');
      } else {
        logger.d('SingleStationHttpProvider: hourly24h failed for $device_id: ${response.statusCode}');
        error = true;
      }
    } catch (e, st) {
      logger.d('SingleStationHttpProvider: hourly24h error for $device_id: $e $st');
      error = true;
    } finally {
      hourly24hReady = true;
      notifyListeners();
    }
  }

  /// Parses JSON array from `/v1/station/historical` with `output_format=json&precision=hour`.
  static List<DataItem> parseHistoricalHourlyJson(String body) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return [];
    }
    if (decoded is! List) return [];

    final SplayTreeMap<DateTime, Map<int, double>> data = SplayTreeMap();
    for (final rawEntry in decoded) {
      if (rawEntry is! Map) continue;
      final entry = Map<String, dynamic>.from(rawEntry);
      final timeRaw = entry['time_measured']?.toString();
      if (timeRaw == null || timeRaw.isEmpty) continue;
      final timeMeasured = DateTime.tryParse(timeRaw);
      if (timeMeasured == null) continue;

      final values = entry['values'];
      if (values is! List) continue;
      for (final rawValue in values) {
        if (rawValue is! Map) continue;
        final valueEntry = Map<String, dynamic>.from(rawValue);
        final dimRaw = valueEntry['dimension'];
        final valRaw = valueEntry['value'];
        if (dimRaw == null || valRaw == null || valRaw is! num) continue;
        final dimension = dimRaw is int ? dimRaw : int.tryParse(dimRaw.toString());
        if (dimension == null) continue;
        data.putIfAbsent(timeMeasured, () => <int, double>{})[dimension] = valRaw.toDouble();
      }
    }

    return data.entries
        .map(
          (entry) => DataItem(
            entry.value[Dimension.PM1_0],
            entry.value[Dimension.PM2_5],
            entry.value[Dimension.PM10_0],
            entry.key,
          ),
        )
        .toList();
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