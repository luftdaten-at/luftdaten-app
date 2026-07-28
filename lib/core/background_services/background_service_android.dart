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

import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/background_services/background_service.dart';
import 'background_service.i18n.dart';
import 'package:luftdaten.at/core/app/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const _foregroundServiceId = 888;
const _notificationIconMetaData = 'at.luftdaten.service.NOTIFICATION_ICON';

class BackgroundServiceAndroid extends BackgroundService {
  BackgroundServiceAndroid() {
    _taskDataCallback = _onTaskData;
  }

  late final void Function(Object data) _taskDataCallback;

  void _onTaskData(Object data) {
    if (data is Map && data['type'] == 'mainHandler') {
      mainHandler(data);
    }
  }

  @override
  void init() {}

  @override
  Future<bool> startTrip(int interval) async {
    logger.d('Starting trip with interval $interval');
    if (!serviceInitialized) {
      await initializeService();
    }

    final permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    final running = await FlutterForegroundTask.isRunningService;
    await FlutterForegroundTask.updateService(
      foregroundTaskOptions: _taskOptions(interval),
    );

    if (running) {
      mainHandler(null);
    } else {
      await FlutterForegroundTask.startService(
        serviceId: _foregroundServiceId,
        serviceTypes: const [ForegroundServiceTypes.connectedDevice],
        notificationTitle: 'Luftdaten.at',
        notificationText: 'Messung gestartet'.i18n,
        notificationIcon: const NotificationIcon(
          metaDataName: _notificationIconMetaData,
        ),
        callback: startForegroundTaskCallback,
      );
    }
    startedTrip = true;
    if (AppSettings.I.wakelock) {
      WakelockPlus.enable();
    }
    return true;
  }

  @override
  void stopTrip() {
    startedTrip = false;
    FlutterForegroundTask.updateService(
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        stopWithTask: true,
      ),
    );
    WakelockPlus.disable();
  }

  @override
  void exit() {
    FlutterForegroundTask.stopService();
    FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback);
    serviceInitialized = false;
    logger.d('Service: exit() called');
  }

  Future<void> initializeService() async {
    logger.d('Initializing Android foreground task');
    if (Platform.isAndroid && !notificationsInitialized) {
      await FlutterLocalNotificationsPlugin().initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('ic_bg_service_small'),
        ),
      );
      notificationsInitialized = true;
    }

    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback);
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ld_foreground',
        channelName: 'Hintergrund-Service'.i18n,
        channelDescription:
            'Informiert Dich, wenn die App im Hintergrund mit einem Messgerät kommuniziert.'.i18n,
        channelImportance: NotificationChannelImportance.HIGH,
        enableVibration: true,
        playSound: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: _taskOptions(60),
    );
    serviceInitialized = true;
    logger.d('Foreground task initialized');
  }

  ForegroundTaskOptions _taskOptions(int intervalSeconds) {
    return ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(intervalSeconds * 1000),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: true,
      stopWithTask: true,
    );
  }
}

@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_LdForegroundTaskHandler());
}

class _LdForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    FlutterForegroundTask.sendDataToMain(const {'type': 'mainHandler'});
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.sendDataToMain(const {'type': 'mainHandler'});
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
