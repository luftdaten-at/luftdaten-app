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

import 'package:device_info_plus/device_info_plus.dart';

import 'device_info.i18n.dart';

class DeviceInfo {
  static Future<void> init() async {
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await DeviceInfoPlugin().iosInfo;
      deviceName = iosDeviceInfo.utsname.machine;
      iOSVersion = iosDeviceInfo.systemVersion;
      iOSPlatform = iosDeviceInfo.systemName;
    } else {
      AndroidDeviceInfo androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      deviceName = androidDeviceInfo.model;
      androidSdk = androidDeviceInfo.version.sdkInt;
    }
  }

  static int? androidSdk;
  static String? iOSVersion;
  static String? iOSPlatform;
  static String? deviceName;

  static String? get androidVersion => _androidSdkToVersion[androidSdk];

  static String get summaryString {
    if (Platform.isIOS) {
      return '%s mit %s %s.'.i18n.fill([deviceName!, iOSPlatform!, iOSVersion!]);
    } else {
      return '%s mit Android %s (SDK %s).'.i18n.fill([deviceName!, androidVersion!, androidSdk!]);
    }
  }

  static final Map<int, String> _androidSdkToVersion = {
    21: '5.0',
    22: '5.1',
    23: '6',
    24: '7.0',
    25: '7.1',
    26: '8.0',
    27: '8.1',
    28: '9',
    29: '10',
    30: '11',
    31: '12',
    32: '12L',
    33: '13',
    34: '14',
    35: '15',
  };
}
