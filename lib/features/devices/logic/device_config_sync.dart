import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_store.dart';

enum DeviceConfigSyncStatus {
  noLocalConfig,
  inSync,
  outOfSync,
  bleReadFailed,
  localOnly,
}

class DeviceConfigSyncResult {
  const DeviceConfigSyncResult({
    required this.status,
    this.localRecord,
    this.portableRecord,
    this.bleSnapshot,
  });

  final DeviceConfigSyncStatus status;
  final StationConfigRecord? localRecord;
  final PortableDeviceConfig? portableRecord;
  final AirStationConfig? bleSnapshot;
}

class DeviceConfigSyncChecker {
  DeviceConfigSyncChecker._();

  static Future<DeviceConfigSyncResult> checkStation(BleDevice device) async {
    final local = await DeviceConfigStore.instance.readStationConfig(device.bleName);
    if (local == null) {
      return const DeviceConfigSyncResult(status: DeviceConfigSyncStatus.noLocalConfig);
    }

    try {
      final raw =
          await getIt<BleController>().readAirStationConfiguration(device);
      if (raw == null || raw.isEmpty) {
        return DeviceConfigSyncResult(
          status: DeviceConfigSyncStatus.bleReadFailed,
          localRecord: local,
        );
      }
      final bleParsed = AirStationConfig.parseFromBytes(device.bleName, raw);
      final inSync = local.config.nonSecretFieldsEqual(bleParsed);
      return DeviceConfigSyncResult(
        status: inSync ? DeviceConfigSyncStatus.inSync : DeviceConfigSyncStatus.outOfSync,
        localRecord: local,
        bleSnapshot: bleParsed,
      );
    } catch (e, st) {
      logger.d('DeviceConfigSyncChecker.checkStation failed: $e $st');
      return DeviceConfigSyncResult(
        status: DeviceConfigSyncStatus.bleReadFailed,
        localRecord: local,
      );
    }
  }

  static DeviceConfigSyncResult portableResult(PortableDeviceConfig? local) {
    if (local == null) {
      return const DeviceConfigSyncResult(status: DeviceConfigSyncStatus.noLocalConfig);
    }
    return DeviceConfigSyncResult(
      status: DeviceConfigSyncStatus.localOnly,
      portableRecord: local,
    );
  }
}
