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
import 'dart:io';
import 'dart:math';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'background_service.i18n.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/core/app/logging.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/measurements/logic/workshop_controller.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';
import 'package:luftdaten.at/features/measurements/data/latlng_with_precision.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/data/trip.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:vibration/vibration.dart';

import 'background_service_android.dart';
import 'background_service_ios.dart';

abstract class BackgroundService {
  late FlutterBackgroundService service;
  bool startedTrip = true;
  bool serviceInitialized = false;
  bool serviceHandlerInitialized = false;
  bool notificationsInitialized = false;

  static BackgroundService forPlatform() {
    if (Platform.isIOS) {
      return BackgroundServiceIOS();
    } else {
      return BackgroundServiceAndroid();
    }
  }

  void init();

  Future<bool> startTrip(int interval);

  void stopTrip();

  void exit();

  void mainHandler(evt) async {
    logger.d('mainHandler invoked');
    Position? position;
    if (AppSettings.I.recordLocation) {
      logger.d('Attempting to find position');
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
        logger.d('Got position: $position');
      } catch (e) {
        logger.e('Failed to get location: $e');
      }
    } else {
      logger.d('Not recording location');
    }
    TripController tripController = getIt<TripController>();
    await Future.wait([
      for (BleDevice device in tripController.ongoingTrips.keys)
        _measureAndHandleForDevice(device, tripController, position)
    ]);
    WorkshopController workshopController = getIt<WorkshopController>();
    if (workshopController.currentWorkshop != null) {
      workshopController.attemptSendData();
    }
  }

  Future<void> _measureAndHandleForDevice(
      BleDevice device, TripController tripController, Position? position) async {
    Trip trip = tripController.ongoingTrips[device]!;
    logger.d('About to read data points');
    List<dynamic> tup;
    try {
      tup = await getIt<BleController>().readSensorValues(device);
    } catch (e, stackTrace) {
      logger.e('Failed to read sensor values from device ${device.bleId}: $e');
      logger.d(stackTrace.toString());
      return;
    }

    List<SensorDataPoint> dataPoints = tup[0];
    Map<String, dynamic> j = tup[1];
    logger.d('Read data points, BLE metadata j=$j (keys=${j.keys.toList()})');

    DateTime timestamp = DateTime.now();
    LatLngWithPrecision? location = position != null
        ? LatLngWithPrecision(position.latitude, position.longitude,
            position.accuracy > 0 ? position.accuracy : null)
        : null;
    logger.d('Converted Position to LatLng');
    trip.addDataPoint(MeasuredDataPoint(
      timestamp: timestamp,
      sensorData: dataPoints,
      location: location,
      mode: tripController.mobilityMode,
      j: j,
    ));
    logger.d('Added data point');
    if (trip.data.length % 5 == 2) {
      trip.save();
    }
    logger.d('About to handle data');
    _handleData(
      trip.data.last.flatten,
      trip.data.length > 1 ? trip.data[trip.data.length - 2].flatten : null,
    );
    logger.d('Handled data');
  }

  void _handleData(FlattenedDataPoint newData, FlattenedDataPoint? mostRecent) {
    if (mostRecent != null) {
      if (newData.isPmElevated() && !mostRecent.isPmElevated() && !newData.isPmHigh()) {
        _notifyUser(false);
      }
      if (newData.isPmHigh() && !mostRecent.isPmHigh()) {
        _notifyUser(true);
      }
    }
  }

  void _notifyUser(bool severe) {
    if (!AppSettings.I.sendNotificationOnExceededThreshold) return;
    String content = 'Aktuelle Feinstaubbelastung überschreitet den WHO-%s-Grenzwert. Tippe, um deine Umgebung mit einer Notiz oder einem Bild zu dokumentieren.'
        .i18n
        .fill([severe ? 'Tagesmittel' : 'Jahresmittel']);
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'luftdaten_pm_threshold',
      'WHO-Grenzwert-Überschreitung'.i18n,
      channelDescription: 'Meldet Überschreitungen der WHO-Feinstaub-Grenzwerte'.i18n,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_pm_threshold',
      styleInformation: BigTextStyleInformation(content),
    );
    DarwinNotificationDetails darwinNotificationDetails = const DarwinNotificationDetails(
      presentBanner: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    FlutterLocalNotificationsPlugin().show(
      Random().nextInt(1000000),
      severe ? 'Erhöhte Feinstaubbelastung'.i18n : 'Stark erhöhte Feinstaubbelastung'.i18n,
      content,
      notificationDetails,
    );
    if (AppSettings.I.vibrateOnExceededThreshold) {
      Vibration.vibrate(duration: 2000);
    }
  }
}
