import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static AppPermission camera = const AppPermission(permission: Permission.camera);
  static AppPermission nearbyDevices = const AppPermission(iosPermission: Permission.bluetooth, androidPermission: Permission.bluetoothConnect);
  static AppPermission locationWhileInUse = const AppPermission(permission: Permission.locationWhenInUse);
  static AppPermission locationAlways = const AppPermission(permission: Permission.locationAlways);
  static AppPermission disableBatteryOptimization = const AppPermission(androidPermission: Permission.ignoreBatteryOptimizations);
  static AppPermission notifications = const AppPermission(permission: Permission.notification);

  static List<AppPermission> get forPlatform {
    if (Platform.isIOS) {
      return [camera, nearbyDevices, locationWhileInUse, locationAlways, notifications];
    } else {
      return [camera, nearbyDevices, locationWhileInUse, locationAlways, disableBatteryOptimization, notifications];
    }
  }
}

class AppPermission {
  final Permission? _permission;
  final Permission? _iosPermission, _androidPermission;

  const AppPermission(
      {Permission? permission, Permission? iosPermission, Permission? androidPermission})
      : _permission = permission,
        _iosPermission = iosPermission,
        _androidPermission = androidPermission;

  bool get _isSplitPlatform => _iosPermission != null || _androidPermission != null;

  bool get appliesToPlatform {
    if (_isSplitPlatform) {
      if (Platform.isIOS) {
        return _iosPermission != null;
      } else if (Platform.isAndroid) {
        return _androidPermission != null;
      }
    }
    return true;
  }

  Future<bool> get granted async {
    if (_isSplitPlatform) {
      if (Platform.isIOS) {
        return await _iosPermission!.isGranted;
      } else if (Platform.isAndroid) {
        return await _androidPermission!.isGranted;
      }
    }
    return await _permission!.isGranted;
  }

  Future<bool> request() async {
    if (_isSplitPlatform) {
      if (Platform.isIOS) {
        return await (_iosPermission!.request()).isGranted;
      } else if (Platform.isAndroid) {
        return await (_androidPermission!.request()).isGranted;
      }
    }
    return await (_permission!.request()).isGranted;
  }
}
