import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'background_service.dart';
import 'background_service.i18n.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../main.dart';
import '../../../features/settings/controllers/app_settings.dart';

class BackgroundServiceAndroid extends BackgroundService {
  @override
  void init() {
    // Initialise service here so that it's not initialised in the background service isolate
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
    serviceInitialized =
    false; /* probably not necessary as exit() should only be called upon exit */
    serviceHandlerInitialized = false;
    logger.d('Service: exit() called');
  }

  /* we have to play Isolate Ping-Pong because the actual work has to be done
     in the main isolate as this is where the BLE communication takes place
     and the data is stored.

     Thus the UI invokes 'startTrip' of the Isolate which starts a timer that
     in turn invokes 'mainHandler' in the main Program. The only purpose of the
     Isolate is to handle the timer and wake up the main thread.
     */
  void serviceHandler() {
    serviceHandlerInitialized = true;
    service.on("mainHandler").listen((evt) => mainHandler(evt));
    logger.d('Service handler initialized');
  }

  Future<void> initializeService() async {
    logger.d('Initializing Android background service');
    AndroidNotificationChannel channel = AndroidNotificationChannel(
        'ld_foreground', 'Hintergrund-Service'.i18n,
        description:
        'Informiert Dich, wenn die App im Hintergrund mit einem Messgerät kommuniziert.'.i18n,
        enableVibration: true,
        importance: Importance.high,
        playSound: true);
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
  service.on('stopTrip').listen((event) {
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
