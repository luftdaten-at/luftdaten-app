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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:logger/logger.dart';
import 'package:luftdaten.at/controller/app_licenses.dart';
import 'package:luftdaten.at/controller/app_settings.dart';
import 'package:luftdaten.at/controller/background_service.dart';
import 'package:luftdaten.at/controller/battery_info_aggregator.dart';
import 'package:luftdaten.at/controller/ble_controller.dart';
import 'package:luftdaten.at/controller/device_info.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/controller/favorites_manager.dart';
import 'package:luftdaten.at/controller/http_provider.dart';
import 'package:luftdaten.at/controller/ld_logger.dart';
import 'package:luftdaten.at/controller/preferences_handler.dart';
import 'package:luftdaten.at/controller/trip_controller.dart';
import 'package:luftdaten.at/controller/workshop_controller.dart';
import 'package:luftdaten.at/page/annotated_picture_page.dart';
import 'package:luftdaten.at/page/ble_serial_page.dart';
import 'package:luftdaten.at/page/chart_page.dart';
import 'package:luftdaten.at/page/enter_workshop_page.dart';
import 'package:luftdaten.at/page/favorites_page.dart';
import 'package:luftdaten.at/page/get_app_page.dart';
import 'package:luftdaten.at/page/licenses_page.dart';
import 'package:luftdaten.at/page/map_page.dart';
import 'package:luftdaten.at/page/nearby_devices_debug_page.dart';
import 'package:luftdaten.at/page/settings_page.dart';
import 'package:luftdaten.at/page/welcome_page.dart';
import 'package:luftdaten.at/page/welcome_wizard_page.dart';
import 'package:luftdaten.at/page/wizard_air_cube_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controller/air_station_config_wizard_controller.dart';
import 'controller/file_handler.dart';
import 'controller/news_controller.dart';
import 'page/device_manager_page.dart';
import 'page/home_page.dart';
import 'page/logging_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  appVersion = packageInfo.version;
  buildNumber = packageInfo.buildNumber;

  await GoogleFonts.pendingFonts([GoogleFonts.nunitoSansTextTheme()]);
  await GetStorage.init('currentTrip');
  await GetStorage.init('preferences');
  await AppSettings.I.init();
  await DeviceInfo.init();

  // Load custom locale if available
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  locale = sharedPreferences.getString('locale');

  if (Platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
  }

  getIt.registerSingleton<DeviceManager>(DeviceManager()..init());
  getIt.registerSingleton<TripController>(TripController()..init());
  //getIt.registerSingleton<TripController>(MockTripController()..init());
  getIt.registerSingleton<BackgroundService>(BackgroundService.forPlatform()..init());
  getIt.registerSingleton<LDHttpProvider>(LDHttpProvider());
  getIt.registerSingleton<SCHttpProvider>(SCHttpProvider()..fetch());
  getIt.registerSingleton<AirStationHttpProvider>(AirStationHttpProvider());
  getIt.registerSingleton<BleController>(BleController());
  getIt.registerSingleton<FileHandler>(FileHandler()..init());
  getIt.registerSingleton<FavoritesManager>(FavoritesManager()..init());
  // The page controller for the home page
  getIt.registerSingleton<PageController>(PageController());
  getIt.registerSingleton<AppLicenses>(AppLicenses()..init());
  getIt.registerSingleton<PreferencesHandler>(PreferencesHandler()..init());
  getIt.registerSingleton<NewsController>(NewsController()..init());
  getIt.registerSingleton<WorkshopController>(WorkshopController()..init());
  getIt.registerSingleton<BatteryInfoAggregator>(BatteryInfoAggregator());

  await AirStationConfigWizardController.init();

  // Initialise the OAuth2 client
  //OAuth2Helper oauth2Helper = OAuth2Helper(
  //  LuftdatenDatahubOAuth2Client(),
  //  grantType: OAuth2Helper.authorizationCode,
  //  clientId: 'GONZXEHrcq7o008XBGvTpUE4EARGLxZ9FxtmZL0z',
  //  clientSecret: LDSecrets.oAuth2ClientSecret,
  //  scopes: [], // Do we need this?
  //);
  //getIt.registerSingleton<OAuth2Helper>(oauth2Helper);

  runApp(LDApp(initialRoute: AppSettings.I.isFirstUse ? WelcomePage.route : '/'));
}

GetIt getIt = GetIt.instance;
GlobalKey globalKey = GlobalKey();

String appVersion = 'error';
String buildNumber = 'error';
String? locale;

Logger logger = Logger(
  printer: LdLogger.I,
  level: Level.trace,
  filter: _LogALlFilter(),
);

class LDApp extends StatefulWidget {
  const LDApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  State<LDApp> createState() => _LDAppState();
}

FToast fToast = FToast();

class _LDAppState extends State<LDApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      key: globalKey,
      value: SystemUiOverlayStyle.dark,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: getIt<DeviceManager>()),
          ChangeNotifierProvider.value(value: getIt<TripController>()),
          Provider.value(value: getIt<BackgroundService>()),
          ChangeNotifierProvider.value(value: getIt<LDHttpProvider>()),
          ChangeNotifierProvider.value(value: getIt<SCHttpProvider>()),
          ChangeNotifierProvider.value(value: getIt<FileHandler>()),
          Provider.value(value: getIt<BleController>()),
        ],
        child: MaterialApp(
          title: 'Luftdaten.at',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2e88c1)),
            primaryColor: const Color(0xff2e88c1),
            useMaterial3: true,
            textTheme: GoogleFonts.nunitoSansTextTheme(),
          ),
          builder: (context, content) {
            return I18n(
              initialLocale: locale != null ? Locale(locale!) : null,
              child: FToastBuilder()(context, Builder(builder: (context) {
                if (fToast.context == null) fToast.init(context);
                return content ?? const SizedBox();
              })),
            );
          },
          initialRoute: widget.initialRoute,
          debugShowCheckedModeBanner: false,
          routes: <String, WidgetBuilder>{
            '/': (ctx) => const PageViewerPage(),
            DeviceManagerPage.route: (ctx) => const DeviceManagerPage(),
            QRCodePage.route: (ctx) => const QRCodePage(),
            QRCodeManualEntryPage.route: (ctx) => const QRCodeManualEntryPage(),
            MapPage.route: (ctx) => const MapPage(),
            LoggingPage.route: (ctx) => const LoggingPage(),
            ChartPage.route: (ctx) => const ChartPage(),
            SettingsPage.route: (ctx) => const SettingsPage(),
            //WelcomePage.route: (ctx) => const WelcomeWizardPage(),
            BLESerialPage.route: (ctx) => const BLESerialPage(),
            GetAppPage.route: (ctx) => const GetAppPage(),
            AnnotatedPicturePage.route: (ctx) => const AnnotatedPicturePage(),
            FavoritesPage.route: (ctx) => const FavoritesPage(),
            LicensesPage.route: (ctx) => const LicensesPage(),
            NearbyDevicesDebugPage.route: (ctx) => const NearbyDevicesDebugPage(),
            EnterWorkshopPage.route: (ctx) => const EnterWorkshopPage(),
            'ak-ws': (ctx) => const EnterWorkshopPage(ak: true),
            'wizard-air-cube': (ctx) => const WizardAirCubePage(),
            'legacy-welcome-page': (ctx) => const WelcomePage(),
            WelcomePage.route: (ctx) => const WelcomeWizardPage(),
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('de'),
            Locale('en'),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        // App minimised or screen is locked
        // If background service is running but we aren't currently measuring, terminate
        if (!getIt<TripController>().isOngoing) {
          getIt<BackgroundService>().exit();
          logger.d('Background service exited!');
        }
        break;
      default:
        break;
    }
  }
}

class _LogALlFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}
