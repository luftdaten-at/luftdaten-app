import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';
import 'package:luftdaten.at/features/devices/data/workshop_configuration.dart';

import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/device_api_key_resolver.dart';
import 'package:luftdaten.at/features/measurements/logic/datahub_measurement_client.dart';
import 'package:luftdaten.at/features/measurements/logic/workshop_datahub_payload.dart';

class WorkshopController extends ChangeNotifier {
  WorkshopConfiguration? _currentWorkshop;

  WorkshopConfiguration? get currentWorkshop => _currentWorkshop;

  /// Latest successfully uploaded measurement timestamp (not wall-clock time).
  DateTime? lastSent;

  /// UI should show a one-shot hint when uploads were skipped for missing API key.
  bool pendingMissingApiKeyHint = false;

  bool? _recordLocationBeforeWorkshop;

  void clearMissingApiKeyHint() {
    if (!pendingMissingApiKeyHint) return;
    pendingMissingApiKeyHint = false;
    notifyListeners();
  }

  set currentWorkshop(WorkshopConfiguration? value) {
    if (value != null) {
      _recordLocationBeforeWorkshop ??= AppSettings.I.recordLocation;
      AppSettings.I.recordLocation = true;
      _currentWorkshop = value;
      pendingMissingApiKeyHint = false;
      _box.write('current', value.toJson());
      periodicallyCheckStatus();
    } else {
      _currentWorkshop = null;
      _box.remove('current');
      pendingMissingApiKeyHint = false;
      if (_recordLocationBeforeWorkshop != null) {
        AppSettings.I.recordLocation = _recordLocationBeforeWorkshop!;
        _recordLocationBeforeWorkshop = null;
      }
    }
    notifyListeners();
  }

  final GetStorage _box = GetStorage('workshop');

  Future<void> init() async {
    await GetStorage.init('workshop');
    if (_box.hasData('current')) {
      logger.d('Loading current workshop from storage');
      final config = WorkshopConfiguration.fromJson(_box.read('current'));
      _recordLocationBeforeWorkshop ??= AppSettings.I.recordLocation;
      AppSettings.I.recordLocation = true;
      _currentWorkshop = config;
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
      final tripController = getIt<TripController>();
      checkIfWorkshopHasEnded();
      if (currentWorkshop == null) return;

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
        logger.d('attemptSendData: no data points with GPS to send, skipping');
        return;
      }

      final workshopId = currentWorkshop!.id.toLowerCase();
      final firmware =
          device.firmwareVersion != null ? device.firmwareVersion!.toString() : '0.0.0';
      final deviceId = device.id;
      logger.d('attemptSendData: workshop=$workshopId, device=$deviceId, firmware=$firmware');
      if (dataPoints.isNotEmpty) {
        _logDeviceIdDebug(device, trip, dataPoints.first);
      }

      final bleMetadata = _bleMetadataSample(dataPoints);
      final apiResolution = await DeviceApiKeyResolver.resolve(
        device: device,
        bleMetadata: bleMetadata,
      );
      logger.d(
        'attemptSendData: apiKey source=${apiResolution.source.name}, '
        'hasKey=${apiResolution.hasKey}',
      );
      final apikey = apiResolution.key ?? '';

      final client = getIt<DatahubMeasurementClient>();
      var sentCount = 0;
      var skippedNoPayload = 0;
      var skippedNoApikey = 0;
      DateTime? latestSentTimestamp;

      if (apikey.isEmpty) {
        skippedNoApikey = dataPoints.length;
      } else {
        for (final dataPoint in dataPoints) {
          Map<String, dynamic>? payload;
          try {
            payload = WorkshopDatahubPayload.build(
              dataPoint: dataPoint,
              deviceChipId: deviceId,
              deviceModelId: trip.deviceModel.id,
              firmware: firmware,
              workshopId: workshopId,
              apikey: apikey,
              participant: currentWorkshop!.participantUid,
            );
          } on ArgumentError catch (e) {
            logger.e('attemptSendData: invalid payload: $e');
            skippedNoPayload++;
            continue;
          }

          if (payload == null) {
            skippedNoPayload++;
            logger.d('attemptSendData: skipping dataPoint (no payload/sensor data or GPS)');
            continue;
          }

          try {
            final statusCode = await client.postWorkshopMeasurement(payload);
            if (statusCode == 200) {
              sentCount++;
              final ts = dataPoint.timestamp;
              if (latestSentTimestamp == null || ts.isAfter(latestSentTimestamp)) {
                latestSentTimestamp = ts;
              }
              logger.d('attemptSendData: sent ok ($sentCount) at ${ts.toIso8601String()}');
            } else {
              logger.e('attemptSendData: HTTP $statusCode');
            }
          } catch (e, st) {
            logger.e('attemptSendData: POST failed: $e');
            logger.d(st.toString());
          }
        }
      }

      if (latestSentTimestamp != null) {
        lastSent = latestSentTimestamp;
      }

      logger.d('attemptSendData: done. sent=$sentCount, skippedNoPayload=$skippedNoPayload, skippedNoApikey=$skippedNoApikey');
      if (skippedNoApikey > 0) {
        logger.d(
          'attemptSendData: no API key — configure api_key on the device firmware, '
          'reconnect over BLE, or use a previously synced key from secure storage.',
        );
      }
      if (sentCount == 0 &&
          skippedNoApikey > 0 &&
          skippedNoApikey == dataPoints.length) {
        pendingMissingApiKeyHint = true;
        notifyListeners();
      }
      if (sentCount > 0) {
        logger.d('Successfully sent $sentCount workshop entries, lastSent=$lastSent');
      }
    } catch (e, stackTrace) {
      logger.e('attemptSendData failed: $e');
      logger.d(stackTrace.toString());
    }
  }

  Map<String, dynamic>? _bleMetadataSample(List<MeasuredDataPoint> dataPoints) {
    for (final p in dataPoints) {
      final j = p.j;
      if (j != null && j.isNotEmpty) return j;
    }
    return dataPoints.isNotEmpty ? dataPoints.first.j : null;
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
    } else {
      logger.d('deviceId debug: BLE metadata j empty (binary format, device sends no JSON)');
    }
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

  void periodicallyCheckStatus() async {
    if (_currentWorkshop == null) return;
    if (_currentWorkshop!.end.isBefore(DateTime.now().toUtc())) {
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
