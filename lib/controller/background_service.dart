import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:luftdaten.at/controller/app_settings.dart';
import 'package:luftdaten.at/controller/background_service.i18n.dart';
import 'package:luftdaten.at/controller/ble_controller.dart';
import 'package:luftdaten.at/controller/trip_controller.dart';
import 'package:luftdaten.at/controller/workshop_controller.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/model/ble_device.dart';
import 'package:luftdaten.at/model/latlng_with_precision.dart';
import 'package:luftdaten.at/models.dart';
import 'package:vibration/vibration.dart';

import '../model/measured_data.dart';
import '../model/trip.dart';
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
    // TODO also check location permission
    logger.d('mainHandler invoked');
    Position? position;
    if(AppSettings.I.recordLocation) {
      logger.d('Attempting to find position');
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
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
    // TODO update map location
  }

  Future<void> _measureAndHandleForDevice(BleDevice device, TripController tripController, Position? position) async {
    Trip trip = tripController.ongoingTrips[device]!;

    logger.d('About to read data points');
    RawMeasurement rawMeasurement = await getIt<BleController>().readSensorValues(device);
    logger.d('Read data points');

    LatLngWithPrecision? location = position != null
        ? LatLngWithPrecision(position.latitude, position.longitude,
        position.accuracy > 0 ? position.accuracy : null)
        : null;

    // add location to RawMeasurement
    rawMeasurement.json["station"]["location"] = {
      "lat": location?.latitude,
      "lon": location?.longitude,
      "height": null,
    };
    logger.d('Added location data to rawMeasurement');

    // add mobility mode
    rawMeasurement.json["station"]["mobility_mode"] = tripController.mobilityMode;
    logger.d('Added mobility mode to rawMeasurement');


    trip.addDataPoint(rawMeasurement);

    logger.d('Added data point');
    if (trip.data.length % 5 == 2) {
      trip.save();
    }

    // TODO send notification
    /*
    logger.d('About to handle data');
    _handleData(
      trip.data.last.flatten,
      trip.data.length > 1 ? trip.data[trip.data.length - 2].flatten : null,
    );

    logger.d('Handled data');
    */
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
    String content =
        'Aktuelle Feinstaubbelastung überschreitet den WHO-%s-Grenzwert. Tippe, um deine Umgebung mit einer Notiz oder einem Bild zu dokumentieren.'
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
      interruptionLevel: (InterruptionLevel.timeSensitive),
    );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    FlutterLocalNotificationsPlugin().show(
      Random().nextInt(1000000), // Should we use one ID and override old notifications?
      severe ? 'Erhöhte Feinstaubbelastung'.i18n : 'Stark erhöhte Feinstaubbelastung'.i18n,
      content,
      notificationDetails,
    );
    if (AppSettings.I.vibrateOnExceededThreshold) {
      Vibration.vibrate(duration: 2000);
    }
  }
}