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

import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings I = AppSettings._();
  AppSettings._();

  bool _isFirstUse = false;
  bool get isFirstUse => _isFirstUse;

  bool _wakelock = true;
  bool get wakelock => _wakelock;
  set wakelock(bool val) {
    _wakelock = val;
    _box.write('wakelock', val);
    notifyListeners();
  }

  bool _showMap = true;
  bool get showMap => _showMap;
  set showMap(bool val) {
    _showMap = val;
    _box.write('showMap', val);
    notifyListeners();
  }

  bool _showOverlay = true;
  bool get showOverlay => _showOverlay;
  set showOverlay(bool val) {
    _showOverlay = val;
    _box.write('showOverlay', val);
    notifyListeners();
  }

  bool _showZoomButtons = false;
  bool get showZoomButtons => _showZoomButtons;
  set showZoomButtons(bool val) {
    _showZoomButtons = val;
    _box.write('showZoomButtons', val);
    notifyListeners();
  }

  bool _followUserDuringMeasurements = true;
  bool get followUserDuringMeasurements => _followUserDuringMeasurements;
  set followUserDuringMeasurements(bool val) {
    _followUserDuringMeasurements = val;
    _box.write('followUserDuringMeasurements', val);
    notifyListeners();
  }

  bool _useLog = false;
  bool get useLog => _useLog;
  set useLog(bool val) {
    _useLog = val;
    _box.write('useLog', val);
    notifyListeners();
  }

  bool _showSerialMonitor = false;
  bool get showSerialMonitor => _showSerialMonitor;
  set showSerialMonitor(bool val) {
    _showSerialMonitor = val;
    _box.write('showSerialMonitor', val);
    notifyListeners();
  }

  bool _defaultToAutoconnect = true;
  bool get defaultToAutoconnect => _defaultToAutoconnect;
  set defaultToAutoconnect(bool val) {
    _defaultToAutoconnect = val;
    _box.write('defaultToAutoconnect', val);
    notifyListeners();
  }

  bool _showCameraButton = true;
  bool get showCameraButton => _showCameraButton;
  set showCameraButton(bool val) {
    _showCameraButton = val;
    _box.write('showCameraButton', val);
    notifyListeners();
  }

  bool _measurePM1 = true;
  bool get measurePM1 => _measurePM1;
  set measurePM1(bool val) {
    _measurePM1 = val;
    _box.write('measurePM1', val);
    notifyListeners();
  }

  bool _measurePM25 = true;
  bool get measurePM25 => _measurePM25;
  set measurePM25(bool val) {
    _measurePM25 = val;
    _box.write('measurePM25', val);
    notifyListeners();
  }

  bool _measurePM4 = true;
  bool get measurePM4 => _measurePM4;
  set measurePM4(bool val) {
    _measurePM4 = val;
    _box.write('measurePM4', val);
    notifyListeners();
  }

  bool _measurePM10 = true;
  bool get measurePM10 => _measurePM10;
  set measurePM10(bool val) {
    _measurePM10 = val;
    _box.write('measurePM10', val);
    notifyListeners();
  }

  bool _measureTemp = true;
  bool get measureTemp => _measureTemp;
  set measureTemp(bool val) {
    _measureTemp = val;
    _box.write('measureTemp', val);
    notifyListeners();
  }

  bool _measureHumidity = true;
  bool get measureHumidity => _measureHumidity;
  set measureHumidity(bool val) {
    _measureHumidity = val;
    _box.write('measureHumidity', val);
    notifyListeners();
  }

  bool _measureVOC = true;
  bool get measureVOC => _measureVOC;
  set measureVOC(bool val) {
    _measureVOC = val;
    _box.write('measureVOC', val);
    notifyListeners();
  }

  bool _measureNOX = true;
  bool get measureNOX => _measureNOX;
  set measureNOX(bool val) {
    _measureNOX = val;
    _box.write('measureNOX', val);
    notifyListeners();
  }

  bool _measurePressure = true;
  bool get measurePressure => _measurePressure;
  set measurePressure(bool val) {
    _measurePressure = val;
    _box.write('measurePressure', val);
    notifyListeners();
  }

  bool _measuresCO2 = true;
  bool get measureCO2 => _measuresCO2;
  set measureCO2(bool val) {
    _measuresCO2 = val;
    _box.write('measuresCO2', val);
    notifyListeners();
  }

  bool _measuresO3 = true;
  bool get measureO3 => _measuresO3;
  set measureO3(bool val) {
    _measuresO3 = val;
    _box.write('measuresO3', val);
    notifyListeners();
  }

  bool _measuresAQI = true;
  bool get measureAQI => _measuresAQI;
  set measureAQI(bool val) {
    _measuresAQI = val;
    _box.write('measuresAQI', val);
    notifyListeners();
  }

  bool _measuresGasResistance = true;
  bool get measureGasResistance => _measuresGasResistance;
  set measureGasResistance(bool val) {
    _measuresGasResistance = val;
    _box.write('measuresGasResistance', val);
    notifyListeners();
  }

  bool _measuresTotalVoc = true;
  bool get measureTotalVoc => _measuresTotalVoc;
  set measureTotalVoc(bool val) {
    _measuresTotalVoc = val;
    _box.write('measuresTotalVoc', val);
    notifyListeners();
  }

  bool _showNotesButton = false;
  bool get showNotesButton => _showNotesButton;
  set showNotesButton(bool val) {
    _showNotesButton = val;
    _box.write('showNotesButton', val);
    notifyListeners();
  }

  bool _sendNotificationOnExceededThreshold = true;
  bool get sendNotificationOnExceededThreshold => _sendNotificationOnExceededThreshold;
  set sendNotificationOnExceededThreshold(bool val) {
    _sendNotificationOnExceededThreshold = val;
    _box.write('sendNotificationOnExceededThreshold', val);
    notifyListeners();
  }

  bool _vibrateOnExceededThreshold = true;
  bool get vibrateOnExceededThreshold => _vibrateOnExceededThreshold;
  set vibrateOnExceededThreshold(bool val) {
    _vibrateOnExceededThreshold = val;
    _box.write('vibrateOnExceededThreshold', val);
    notifyListeners();
  }

  bool _recordLocation = true;
  bool get recordLocation => _recordLocation;
  set recordLocation(bool val) {
    _recordLocation = val;
    _box.write('recordLocation', val);
    notifyListeners();
  }

  bool _enableMultiDeviceMeasurements = false;
  bool get enableMultiDeviceMeasurements => _enableMultiDeviceMeasurements;
  set enableMultiDeviceMeasurements(bool val) {
    _enableMultiDeviceMeasurements = val;
    _box.write('enableMultiDeviceMeasurements', val);
    notifyListeners();
  }

  bool _dashboardShowAirStations = true;
  bool get dashboardShowAirStations => _dashboardShowAirStations;
  set dashboardShowAirStations(bool val) {
    _dashboardShowAirStations = val;
    _box.write('dashboardShowAirStations', val);
    notifyListeners();
  }

  bool _dashboardShowFavorites = true;
  bool get dashboardShowFavorites => _dashboardShowFavorites;
  set dashboardShowFavorites(bool val) {
    _dashboardShowFavorites = val;
    _box.write('dashboardShowFavorites', val);
    notifyListeners();
  }

  bool _dashboardShowPortables = true;
  bool get dashboardShowPortables => _dashboardShowPortables;
  set dashboardShowPortables(bool val) {
    _dashboardShowPortables = val;
    _box.write('dashboardShowPortables', val);
    notifyListeners();
  }

  bool _useStagingServer = false;
  bool get useStagingServer => _useStagingServer;
  set useStagingServer(bool val) {
    _useStagingServer = val;
    _box.write('useStagingServer', val);
    notifyListeners();
  }

  bool _showBatteryGraph = false;
  bool get showBatteryGraph => _showBatteryGraph;
  set showBatteryGraph(bool val) {
    _showBatteryGraph = val;
    _box.write('showBatteryGraph', val);
    notifyListeners();
  }

  final GetStorage _box = GetStorage('settings');

  Future<void> init() async {
    await GetStorage.init('settings');
    _isFirstUse = !(_box.read('opened') ?? false);
    wakelock = _box.read('wakelock') ?? true;
    showMap = _box.read('showMap') ?? true;
    showOverlay = _box.read('showOverlay') ?? true;
    showZoomButtons = _box.read('showZoomButtons') ?? false;
    followUserDuringMeasurements = _box.read('followUserDuringMeasurements') ?? true;
    useLog = _box.read('useLog') ?? false;
    showSerialMonitor = _box.read('showSerialMonitor') ?? false;
    defaultToAutoconnect = _box.read('defaultToAutoconnect') ?? true;
    showCameraButton = _box.read('showCameraButton') ?? true;
    measurePM1 = _box.read('measurePM1') ?? true;
    measurePM25 = _box.read('measurePM25') ?? true;
    measurePM4 = _box.read('measurePM4') ?? true;
    measurePM10 = _box.read('measurePM10') ?? true;
    measureTemp = _box.read('measureTemp') ?? true;
    measureHumidity = _box.read('measureHumidity') ?? true;
    measureVOC = _box.read('measureVOC') ?? true;
    measureNOX = _box.read('measureNOX') ?? true;
    measurePressure = _box.read('measurePressure') ?? true;
    measureCO2 = _box.read('measuresCO2') ?? true;
    measureO3 = _box.read('measuresO3') ?? true;
    measureAQI = _box.read('measuresAQI') ?? true;
    measureGasResistance = _box.read('measuresGasResistance') ?? true;
    measureTotalVoc = _box.read('measuresTotalVoc') ?? true;
    showNotesButton = _box.read('showNotesButton') ?? false;
    sendNotificationOnExceededThreshold = _box.read('sendNotificationOnExceededThreshold') ?? true;
    vibrateOnExceededThreshold = _box.read('vibrateOnExceededThreshold') ?? true;
    recordLocation = _box.read('recordLocation') ?? true;
    enableMultiDeviceMeasurements = _box.read('enableMultiDeviceMeasurements') ?? false;
    dashboardShowAirStations = _box.read('dashboardShowAirStations') ?? true;
    dashboardShowFavorites = _box.read('dashboardShowFavorites') ?? true;
    dashboardShowPortables = _box.read('dashboardShowPortables') ?? true;
    useStagingServer = _box.read('useStagingServer') ?? false;
    showBatteryGraph = _box.read('showBatteryGraph') ?? false;
    _box.write('opened', true);
  }
}
