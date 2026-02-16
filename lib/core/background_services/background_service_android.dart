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
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/background_services/background_service.dart';
import 'background_service.i18n.dart';
import 'package:luftdaten.at/core/app/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class BackgroundServiceAndroid extends BackgroundService {
  @override
  void init() {
    service = FlutterBackgroundService();
  }

  @override
  Future<bool> startTrip(int interval) async {
    logger.d('Starting trip with interval $interval');
    if (!serviceInitialized) {
      await initializeService();
    }
    service.invoke("startTrip", {
      "seconds": interval,
    });
    startedTrip = true;
    if (AppSettings.I.wakelock) {
      WakelockPlus.enable();
    }
    return true;
  }

  @override
  void stopTrip() {
    startedTrip = false;
    service.invoke("stopTrip");
    WakelockPlus.disable();
  }

  @override
  void exit() {
    service.invoke("stop");
    serviceInitialized = false;
    serviceHandlerInitialized = false;
    logger.d('Service: exit() called');
  }

  void serviceHandler() {
    serviceHandlerInitialized = true;
    service.on("mainHandler").listen((evt) => mainHandler(evt));
    logger.d('Service handler initialized');
  }

  Future<void> initializeService() async {
    logger.d('Initializing Android background service');
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ld_foreground',
      'Hintergrund-Service'.i18n,
      description:
          'Informiert Dich, wenn die App im Hintergrund mit einem Messgerät kommuniziert.'.i18n,
      enableVibration: true,
      importance: Importance.high,
      playSound: true,
    );
    if (Platform.isIOS || Platform.isAndroid) {
      if (!notificationsInitialized) {
        await FlutterLocalNotificationsPlugin().initialize(
          const InitializationSettings(
            iOS: DarwinInitializationSettings(),
            android: AndroidInitializationSettings("ic_bg_service_small"),
          ),
        );
        notificationsInitialized = true;
      }
    }

    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: 'ld_foreground',
        initialNotificationTitle: 'Luftdaten.at',
        initialNotificationContent: 'Messung gestartet'.i18n,
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );

    await service.startService();
    if (!serviceHandlerInitialized) serviceHandler();
    serviceInitialized = true;
    logger.d('Background service initialized and started');
  }
}

Timer? tripTimer;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stop').listen((_) => service.stopSelf());
  service.on('stopTrip').listen((_) {
    tripTimer?.cancel();
    tripTimer = null;
  });
  service.on('startTrip').listen((event) {
    tripTimer?.cancel();
    logger.d('Service isolate: startTrip event received');
    int duration = event!['seconds'];
    service.invoke("mainHandler", event);
    tripTimer = Timer.periodic(Duration(seconds: duration), (timer) async {
      service.invoke("mainHandler", event);
    });
  });
}
