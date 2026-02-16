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

import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luftdaten.at/core/app/app.dart';
import 'package:luftdaten.at/core/config/app_licenses.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/background_services/background_service.dart';
import 'package:luftdaten.at/core/app/device_info.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/core/config/env.dart';
import 'package:luftdaten.at/features/dashboard/logic/news_controller.dart';
import 'package:luftdaten.at/core/app/preferences_handler.dart';
import 'package:luftdaten.at/features/devices/logic/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/dashboard/logic/favorites_manager.dart';
import 'package:luftdaten.at/features/dashboard/logic/http_provider.dart';
import 'package:luftdaten.at/features/measurements/logic/file_handler.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';
import 'package:luftdaten.at/features/measurements/logic/workshop_controller.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/core/app/presentation/welcome_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns true if this is a map tile loading error (connection reset, etc.).
/// These are common under load/rate limiting and should not spam the console.
bool _isTileLoadingError(Object exception) {
  final msg = exception.toString();
  return msg.contains('tile.openstreetmap.org') &&
      (msg.contains('SocketException') ||
          msg.contains('Connection reset') ||
          msg.contains('ClientException'));
}

void main() async {
  runZonedGuarded(() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_isTileLoadingError(details.exception)) return;
      FlutterError.dumpErrorToConsole(details);
    };

    WidgetsFlutterBinding.ensureInitialized();

    // Suppress i18n missing translation warnings (e.g. de-AT fallback to de)
    Translations.missingKeyCallback = (_, __) {};
    Translations.missingTranslationCallback = ({required key, required locale, required translations, required supportedLocales}) => false;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    buildNumber = packageInfo.buildNumber;

    await GoogleFonts.pendingFonts([GoogleFonts.nunitoSansTextTheme()]);
    await GetStorage.init('currentTrip');
    await GetStorage.init('preferences');
    await AppSettings.I.init();
    await DeviceInfo.init();

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    locale = sharedPreferences.getString('locale');

    if (Platform.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }

    getIt.registerSingleton<DeviceManager>(DeviceManager()..init());
    getIt.registerSingleton<TripController>(TripController()..init());
    getIt.registerSingleton<BackgroundService>(BackgroundService.forPlatform()..init());
    getIt.registerSingleton<MapHttpProvider>(MapHttpProvider()..fetch());
    getIt.registerSingleton<BleController>(BleController());
    getIt.registerSingleton<FileHandler>(FileHandler()..init());
    getIt.registerSingleton<FavoritesManager>(FavoritesManager()..init());
    getIt.registerSingleton<PageController>(PageController());
    getIt.registerSingleton<AppLicenses>(AppLicenses()..init());
    getIt.registerSingleton<PreferencesHandler>(PreferencesHandler()..init());
    getIt.registerSingleton<NewsController>(NewsController()..init());
    getIt.registerSingleton<WorkshopController>(WorkshopController()..init());
    getIt.registerSingleton<BatteryInfoAggregator>(BatteryInfoAggregator());

    await AirStationConfigWizardController.init();
    await AirStationConfigManager.loadAllConfigs();

    runApp(LDApp(initialRoute: AppSettings.I.isFirstUse ? WelcomePage.route : '/'));
  }, (Object error, StackTrace stack) {
    if (_isTileLoadingError(error)) return;
    FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack));
  });
}
