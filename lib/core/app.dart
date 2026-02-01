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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:luftdaten.at/core/background_service.dart';
import 'package:luftdaten.at/core/di.dart';
import 'package:luftdaten.at/core/env.dart';
import 'package:luftdaten.at/core/logging.dart';
import 'package:luftdaten.at/controller/ble_controller.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/controller/http_provider.dart';
import 'package:luftdaten.at/features/measurement/controllers/file_handler.dart';
import 'package:luftdaten.at/features/measurement/controllers/trip_controller.dart';
import 'package:luftdaten.at/features/measurement/pages/annotated_picture_page.dart';
import 'package:luftdaten.at/features/measurement/pages/chart_page.dart';
import 'package:luftdaten.at/page/ble_serial_page.dart';
import 'package:luftdaten.at/page/device_manager_page.dart';
import 'package:luftdaten.at/page/enter_workshop_page.dart';
import 'package:luftdaten.at/page/home_page.dart';
import 'package:luftdaten.at/page/favorites_page.dart';
import 'package:luftdaten.at/page/get_app_page.dart';
import 'package:luftdaten.at/page/licenses_page.dart';
import 'package:luftdaten.at/features/measurement/pages/logging_page.dart';
import 'package:luftdaten.at/page/map_page.dart';
import 'package:luftdaten.at/page/nearby_devices_debug_page.dart';
import 'package:luftdaten.at/page/settings_page.dart';
import 'package:luftdaten.at/page/welcome_page.dart';
import 'package:luftdaten.at/page/welcome_wizard_page.dart';
import 'package:luftdaten.at/page/wizard_air_cube_page.dart';
import 'package:provider/provider.dart';

class LDApp extends StatefulWidget {
  const LDApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  State<LDApp> createState() => _LDAppState();
}

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
          ChangeNotifierProvider.value(value: getIt<MapHttpProvider>()),
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
