import 'package:flutter/foundation.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/datahub_api_key_generator.dart';
import 'package:luftdaten.at/features/devices/logic/datahub_device_registration_client.dart';
import 'package:luftdaten.at/features/devices/logic/device_api_key_ble_sync.dart';
import 'package:luftdaten.at/features/devices/logic/device_api_key_resolver.dart';

/// Ensures an Air Badge is registered in Datahub after the first successful connect.
class BadgeDatahubRegistration {
  BadgeDatahubRegistration._();

  static Future<void> ensureRegistered(BleDevice device) async {
    if (device.model != LDDeviceModel.badge) return;
    if (device.isMock && AppSettings.mockBleActive) return;

    await DeviceApiKeyResolver.hydrateDeviceFromSecureStorage(device);
    if (device.datahubRegistrationChecked && device.apiKey?.trim().isNotEmpty == true) {
      return;
    }

    await ensureRegisteredInternal(
      device,
      client: getIt<DatahubDeviceRegistrationClient>(),
      sendApiKey: (d, key) => getIt<BleController>().sendPortableApiKey(d, key),
      generateApiKey: DatahubApiKeyGenerator.generate,
      refreshDeviceInfo: (d) => getIt<BleController>().refreshDeviceInfo(d),
    );
  }

  @visibleForTesting
  static Future<void> ensureRegisteredInternal(
    BleDevice device, {
    required DatahubDeviceRegistrationClient client,
    required Future<bool> Function(BleDevice device, String apiKey) sendApiKey,
    required String Function() generateApiKey,
    required Future<void> Function(BleDevice device) refreshDeviceInfo,
  }) async {
    final deviceId = device.chipIdForApi;

    try {
      await DeviceApiKeyResolver.hydrateDeviceFromSecureStorage(device);

      if (await client.isDeviceRegistered(deviceId)) {
        logger.d('BadgeDatahubRegistration: $deviceId already registered');
        final existingKey = device.apiKey?.trim();
        if (existingKey != null && existingKey.isNotEmpty) {
          final pushed = await sendApiKey(device, existingKey);
          if (pushed) {
            await refreshDeviceInfo(device);
          }
          await DeviceApiKeyBleSync.applyKey(
            device,
            existingKey,
            logSource: 'badge_datahub_registration',
          );
          device.markDatahubRegistrationChecked();
          return;
        }
        logger.d(
          'BadgeDatahubRegistration: $deviceId registered in Datahub but badge has no api key — provisioning',
        );
      }

      final hadKeyOnDevice = device.apiKey?.trim().isNotEmpty == true;
      final apiKey = hadKeyOnDevice ? device.apiKey!.trim() : generateApiKey();
      if (!hadKeyOnDevice) {
        logger.d('BadgeDatahubRegistration: generated api key for $deviceId');
        await DeviceApiKeyBleSync.applyKey(
          device,
          apiKey,
          logSource: 'badge_datahub_provisioning_pending',
        );
      }

      final registerResult = await client.registerBadgeDevice(device, apiKey: apiKey);
      if (registerResult == DatahubRegisterResult.wrongApiKey) {
        logger.d(
          'BadgeDatahubRegistration: Datahub rejected api key for $deviceId '
          '(device already has a different key) — pushing key to badge',
        );
        final pushed = await _pushApiKeyToBadge(
          device,
          apiKey,
          sendApiKey: sendApiKey,
          refreshDeviceInfo: refreshDeviceInfo,
          logSource: 'badge_datahub_wrong_api_key',
        );
        if (!pushed) {
          logger.d('BadgeDatahubRegistration: BLE api key write failed for $deviceId');
        }
        return;
      }
      if (registerResult != DatahubRegisterResult.success) {
        logger.d('BadgeDatahubRegistration: register failed for $deviceId');
        return;
      }

      logger.d('BadgeDatahubRegistration: registered $deviceId in Datahub');

      if (!hadKeyOnDevice) {
        final pushed = await _pushApiKeyToBadge(
          device,
          apiKey,
          sendApiKey: sendApiKey,
          refreshDeviceInfo: refreshDeviceInfo,
          logSource: 'badge_datahub_provisioning',
        );
        if (!pushed) {
          logger.d('BadgeDatahubRegistration: BLE api key write failed for $deviceId');
          return;
        }
      } else {
        await DeviceApiKeyBleSync.applyKey(
          device,
          apiKey,
          logSource: 'badge_datahub_registration',
        );
      }

      device.markDatahubRegistrationChecked();
    } catch (e, st) {
      logger.d('BadgeDatahubRegistration: error for $deviceId: $e $st');
    }
  }

  static Future<bool> _pushApiKeyToBadge(
    BleDevice device,
    String apiKey, {
    required Future<bool> Function(BleDevice device, String apiKey) sendApiKey,
    required Future<void> Function(BleDevice device) refreshDeviceInfo,
    required String logSource,
  }) async {
    final pushed = await sendApiKey(device, apiKey);
    if (!pushed) return false;
    await DeviceApiKeyBleSync.applyKey(device, apiKey, logSource: logSource);
    await refreshDeviceInfo(device);
    return true;
  }
}
