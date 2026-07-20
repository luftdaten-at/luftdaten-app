import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_datahub_registration.dart';
import 'package:luftdaten.at/features/devices/logic/datahub_device_registration_client.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

BleDevice _badgeDevice() {
  return BleDevice(
    model: LDDeviceModel.badge,
    bleName: 'Luftdaten.at-Badge-ABCD1234EF56',
    bleMacAddress: 'ABCD1234EF56',
    deviceOriginalDisplayName: 'ABCD1234EF56',
    bleId: 'test-ble-id',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DeviceManager deviceManager;

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') return '/tmp';
      if (methodCall.method == 'getTemporaryDirectory') return '/tmp';
      return null;
    });
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await GetStorage.init('devices');
    GetStorage('devices').remove('devices');
    getIt.reset();
    deviceManager = DeviceManager();
    getIt.registerSingleton<DeviceManager>(deviceManager);
  });

  tearDown(() {
    getIt.reset();
  });

  group('BadgeDatahubRegistration.ensureRegisteredInternal', () {
    test('generates key, registers, pushes BLE, and marks checked', () async {
      final device = _badgeDevice();
      deviceManager.addDevice(device);

      String? registeredKey;
      String? pushedKey;

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response('{"detail":"Device not found."}', 404);
          }
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          registeredKey = body['device']['apikey'] as String;
          expect(registeredKey, isNotEmpty);
          return http.Response('{"status":"success"}', 200);
        }),
      );

      await BadgeDatahubRegistration.ensureRegisteredInternal(
        device,
        client: client,
        sendApiKey: (_, key) async {
          pushedKey = key;
          return true;
        },
        generateApiKey: () => 'generatedapikey012345678901234',
        refreshDeviceInfo: (_) async {},
      );

      expect(registeredKey, 'generatedapikey012345678901234');
      expect(pushedKey, 'generatedapikey012345678901234');
      expect(device.apiKey, 'generatedapikey012345678901234');
      expect(device.datahubRegistrationChecked, isTrue);
    });

    test('marks checked and pushes key when already registered with api key', () async {
      final device = _badgeDevice()..apiKey = 'existing-badge-key-12345678';
      deviceManager.addDevice(device);
      String? pushedKey;

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          return http.Response(
            '{"device":"ABCD1234EF56","device_name":"Badge"}',
            200,
          );
        }),
      );

      await BadgeDatahubRegistration.ensureRegisteredInternal(
        device,
        client: client,
        sendApiKey: (_, key) async {
          pushedKey = key;
          return true;
        },
        generateApiKey: () => 'unused',
        refreshDeviceInfo: (_) async {},
      );

      expect(pushedKey, 'existing-badge-key-12345678');
      expect(device.datahubRegistrationChecked, isTrue);
    });

    test('provisions when already registered but badge has no api key', () async {
      final device = _badgeDevice();
      deviceManager.addDevice(device);
      var postCount = 0;
      String? pushedKey;

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              '{"device":"ABCD1234EF56","device_name":"Badge"}',
              200,
            );
          }
          postCount++;
          return http.Response('{"status":"success"}', 200);
        }),
      );

      await BadgeDatahubRegistration.ensureRegisteredInternal(
        device,
        client: client,
        sendApiKey: (_, key) async {
          pushedKey = key;
          return true;
        },
        generateApiKey: () => 'generatedapikey012345678901234',
        refreshDeviceInfo: (_) async {},
      );

      expect(postCount, 1);
      expect(pushedKey, 'generatedapikey012345678901234');
      expect(device.datahubRegistrationChecked, isTrue);
    });

    test('does not mark checked when register fails after Datahub lookup 404', () async {
      final device = _badgeDevice();
      String? pushedKey;

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response('{"detail":"Device not found."}', 404);
          }
          return http.Response('["Wrong API Key"]', 400);
        }),
      );

      await BadgeDatahubRegistration.ensureRegisteredInternal(
        device,
        client: client,
        sendApiKey: (_, key) async {
          pushedKey = key;
          return true;
        },
        generateApiKey: () => 'generatedapikey012345678901234',
        refreshDeviceInfo: (_) async {},
      );

      expect(pushedKey, 'generatedapikey012345678901234');
      expect(device.apiKey, 'generatedapikey012345678901234');
      expect(device.datahubRegistrationChecked, isFalse);
    });

    test('pushes key to badge when already registered but Datahub rejects api key', () async {
      final device = _badgeDevice();
      deviceManager.addDevice(device);
      String? pushedKey;

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              '{"device":"ABCD1234EF56","device_name":"Badge"}',
              200,
            );
          }
          return http.Response('["Wrong API Key"]', 400);
        }),
      );

      await BadgeDatahubRegistration.ensureRegisteredInternal(
        device,
        client: client,
        sendApiKey: (_, key) async {
          pushedKey = key;
          return true;
        },
        generateApiKey: () => 'generatedapikey012345678901234',
        refreshDeviceInfo: (_) async {},
      );

      expect(pushedKey, 'generatedapikey012345678901234');
      expect(device.apiKey, 'generatedapikey012345678901234');
      expect(device.datahubRegistrationChecked, isFalse);
    });

    test('does not mark checked when already registered but register POST fails', () async {
      final device = _badgeDevice();

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              '{"device":"ABCD1234EF56","device_name":"Badge"}',
              200,
            );
          }
          return http.Response('{"detail":"Server error"}', 500);
        }),
      );

      await BadgeDatahubRegistration.ensureRegisteredInternal(
        device,
        client: client,
        sendApiKey: (_, __) async => true,
        generateApiKey: () => 'generatedapikey012345678901234',
        refreshDeviceInfo: (_) async {},
      );

      expect(device.datahubRegistrationChecked, isFalse);
    });

    test('does not mark checked when BLE push fails after register', () async {
      final device = _badgeDevice();

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response('{"detail":"Device not found."}', 404);
          }
          return http.Response('{"status":"success"}', 200);
        }),
      );

      await BadgeDatahubRegistration.ensureRegisteredInternal(
        device,
        client: client,
        sendApiKey: (_, __) async => false,
        generateApiKey: () => 'generatedapikey012345678901234',
        refreshDeviceInfo: (_) async {},
      );

      expect(device.datahubRegistrationChecked, isFalse);
    });
  });
}
