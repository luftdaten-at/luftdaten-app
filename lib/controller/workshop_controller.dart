import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';
import 'package:luftdaten.at/features/measurement/controllers/trip_controller.dart';
import 'package:luftdaten.at/model/workshop_configuration.dart';

import 'package:luftdaten.at/core/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/measurement/models/measured_data.dart';
import 'package:luftdaten.at/util/ble_json_parser.dart';
import 'package:luftdaten.at/features/measurement/models/trip.dart';
import 'package:luftdaten.at/model/ble_device.dart';

class WorkshopController extends ChangeNotifier {
  WorkshopConfiguration? _currentWorkshop;

  WorkshopConfiguration? get currentWorkshop => _currentWorkshop;

  DateTime? lastSent;

  set currentWorkshop(WorkshopConfiguration? value) {
    _currentWorkshop = value;
    if (value != null) {
      _box.write('current', value.toJson());
      periodicallyCheckStatus();
    } else {
      _box.remove('current');
    }
    notifyListeners();
  }

  final GetStorage _box = GetStorage('workshop');

  Future<void> init() async {
    await GetStorage.init('workshop');
    if (_box.hasData('current')) {
      logger.d('Loading current workshop from storage');
      currentWorkshop = WorkshopConfiguration.fromJson(_box.read('current'));
      checkIfWorkshopHasEnded();
    }
    notifyListeners();
  }

  String get serverUrl => AppSettings.I.useStagingServer ? 'staging.datahub.luftdaten.at' : 'datahub.luftdaten.at';

  void checkIfWorkshopHasEnded() {
    if (currentWorkshop != null && currentWorkshop!.end.toUtc().isBefore(DateTime.now().toUtc())) {
      exitWorkshop();
    }
  }

  void exitWorkshop() {
    currentWorkshop = null;
  }

  void attemptSendData() async {
    try {
      logger.d('attemptSendData: currentWorkshop=${currentWorkshop?.id}, lastSent=$lastSent');
      if (currentWorkshop == null) {
        logger.d('attemptSendData: no workshop, skipping');
        return;
      }
      TripController tripController = getIt<TripController>();
      checkIfWorkshopHasEnded();
      if (currentWorkshop != null) {
        if (tripController.ongoingTrips.isEmpty) {
          logger.d('attemptSendData: no ongoing trips, skipping');
          return;
        }
        final entry = tripController.ongoingTrips.entries.first;
        final device = entry.key;
        final trip = entry.value;

        List<MeasuredDataPoint> dataPoints = lastSent == null
            ? trip.data
            : trip.data.where((e) => e.timestamp.isAfter(lastSent!)).toList();
        final afterLastSent = dataPoints.length;
        dataPoints = dataPoints.where((e) => e.location != null).toList();
        logger.d('attemptSendData: trip has ${trip.data.length} points, '
            '$afterLastSent after lastSent filter, ${dataPoints.length} with location');

        if (dataPoints.isEmpty) {
          logger.d('attemptSendData: no data points to send, skipping');
          return;
        }

        final workshopId = currentWorkshop!.id.toLowerCase();
        final firmware =
            device.firmwareVersion != null
                ? device.firmwareVersion!.toString()
                : '0.0.0';
        final deviceId = _deviceIdForWorkshop(device);
        final url = 'https://$serverUrl/api/v1/devices/data/';
        logger.d('attemptSendData: workshop=$workshopId, device=$deviceId, firmware=$firmware, url=$url');
        if (dataPoints.isNotEmpty) {
          _logDeviceIdDebug(device, trip, dataPoints.first);
        }

        int sentCount = 0;
        int skippedNoPayload = 0;
        int skippedNoApikey = 0;
        for (final dataPoint in dataPoints) {
          final apikey = _apikeyFromDataPoint(dataPoint, device: device) ?? '';
          if (apikey.isEmpty) {
            skippedNoApikey++;
            continue;
          }
          final payload = _buildWorkshopPayload(
            dataPoint: dataPoint,
            deviceChipId: deviceId,
            deviceModelId: trip.deviceModel.id,
            firmware: firmware,
            workshopId: workshopId,
            apikey: apikey,
            participant: currentWorkshop!.participantUid,
          );
          if (payload == null) {
            skippedNoPayload++;
            logger.d('attemptSendData: skipping dataPoint (no payload/sensor data)');
            continue;
          }

          final body = json.encode(payload);
          logger.d('attemptSendData: POST $url');
          logger.d('attemptSendData: payload=$body');

          try {
            final res = await post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: body,
            );
            logger.d('attemptSendData: response status=${res.statusCode}, body=${res.body}');
            if (res.statusCode == 200) {
              sentCount++;
              lastSent = DateTime.now();
              logger.d('attemptSendData: sent ok (${sentCount}), lastSent=$lastSent');
            } else {
              logger.e('attemptSendData: HTTP ${res.statusCode} - ${res.body}');
            }
          } catch (e, st) {
            logger.e('attemptSendData: POST failed: $e');
            logger.d(st.toString());
          }
        }
        logger.d('attemptSendData: done. sent=$sentCount, skippedNoPayload=$skippedNoPayload, skippedNoApikey=$skippedNoApikey');
        if (skippedNoApikey > 0) {
          logger.d('attemptSendData: no API key from BLE (device may use binary format). Configure API key on device or update firmware.');
        }
        if (sentCount > 0) {
          logger.d('Successfully sent $sentCount workshop entries, next send after ${lastSent!.toIso8601String()}');
        }
      }
    } catch (e, stackTrace) {
      logger.e('attemptSendData failed: $e');
      logger.d(stackTrace.toString());
    }
  }

  /// Apikey from BLE device metadata (dataPoint.j) or device.
  /// CircuitPython sends station.api.key, station.apikey, or top-level apikey.
  String? _apikeyFromDataPoint(MeasuredDataPoint dataPoint, {BleDevice? device}) {
    return BleJsonParser.parseApiKey(dataPoint.j) ?? device?.apiKey;
  }

  void _logDeviceIdDebug(BleDevice device, Trip trip, MeasuredDataPoint dataPoint) {
    logger.d('deviceId debug: BleDevice.deviceOriginalDisplayName=${device.deviceOriginalDisplayName}');
    logger.d('deviceId debug: BleDevice.bleMacAddress=${device.bleMacAddress}');
    logger.d('deviceId debug: BleDevice.id=${device.id}, chipIdForApi=${device.chipIdForApi}');
    logger.d('deviceId debug: Trip.deviceChipId.chipId=${trip.deviceChipId.chipId}');
    if (trip.sensorDetails != null) {
      for (var i = 0; i < trip.sensorDetails!.length; i++) {
        final s = trip.sensorDetails![i];
        logger.d('deviceId debug: Trip.sensorDetails[$i] serialNumber=${s.serialNumber}');
      }
    } else {
      logger.d('deviceId debug: Trip.sensorDetails=null');
    }
    final j = dataPoint.j;
    if (j != null && j.isNotEmpty) {
      logger.d('deviceId debug: BLE metadata j (from device): $j');
      logger.d('deviceId debug: j.device=${j['device']}, j.id=${j['id']}, j.station=${j['station']}');
      final dev = j['device'];
      if (dev is Map) {
        final dm = dev as Map<String, dynamic>;
        logger.d('deviceId debug: j.device keys=${dm.keys.toList()}, id=${dm['id']}, settings=${dm['settings']}');
      }
    } else {
      logger.d('deviceId debug: BLE metadata j empty (binary format, device sends no JSON)');
    }
    final used = _deviceIdForWorkshop(device);
    logger.d('deviceId debug: _deviceIdForWorkshop result (used in payload)=$used');
  }

  /// Device ID for workshop API.
  String _deviceIdForWorkshop(BleDevice device) {
    return device.id;
  }

  /// Builds the API payload from a MeasuredDataPoint.
  /// Returns null if the data point has no sensor data.
  Map<String, dynamic>? _buildWorkshopPayload({
    required MeasuredDataPoint dataPoint,
    required String deviceChipId,
    required int deviceModelId,
    required String firmware,
    required String workshopId,
    required String apikey,
    required String participant,
  }) {
    if (dataPoint.sensorData.isEmpty) return null;

    final sensors = <String, dynamic>{};
    for (var i = 0; i < dataPoint.sensorData.length; i++) {
      final sp = dataPoint.sensorData[i];
      if (sp.sensor == LDSensor.unknown) continue;

      final data = <String, dynamic>{};
      for (final entry in sp.values.entries) {
        if (entry.key != MeasurableQuantity.unknown) {
          final v = entry.value;
          // json.encode throws on NaN/Infinity
          data['${entry.key.id}'] =
              (v.isNaN || v.isInfinite) ? null : v;
        }
      }
      if (data.isNotEmpty) {
        sensors['${i + 1}'] = {
          'type': sp.sensor.id,
          'data': data,
        };
      }
    }
    if (sensors.isEmpty) return null;

    return {
      'device': {
        'time': dataPoint.timestamp.toUtc().toIso8601String(),
        'id': deviceChipId,
        'firmware': firmware,
        'model': deviceModelId,
        'apikey': apikey,
      },
      'workshop': {
        'id': workshopId,
        'participant': participant,
        'mode': dataPoint.mode?.name ?? 'walking',
      },
      'sensors': sensors,
    };
  }

  Future<WorkshopConfiguration> loadWorkshopDetails(String id) async {
    id = id.toLowerCase();
    Response res;
    try {
      res = await get(Uri.parse('https://$serverUrl/api/workshop/detail/$id/'));
    } catch (_) {
      throw ConnectionError();
    }
    if (res.statusCode != 200) {
      throw InvalidIdError(id);
    }
    return WorkshopConfiguration.fromJson(json.decode(utf8.decode(res.bodyBytes)));
  }

  // We can check frequently, this function is inexpensive
  void periodicallyCheckStatus() async {
    if(_currentWorkshop == null) return;
    if(_currentWorkshop!.end.isBefore(DateTime.now().toUtc())) {
      exitWorkshop();
      return;
    }
    await Future.delayed(const Duration(seconds: 30));
  }
}

class ConnectionError extends Error {
  ConnectionError();
}

class InvalidIdError extends Error {
  final String id;

  InvalidIdError(this.id);
}

extension FormatAsWorkshopId on String {
  String get formatAsId => '${substring(0, 3).toUpperCase()}-${substring(3).toUpperCase()}';
}
