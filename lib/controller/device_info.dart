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
