import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/datahub_device_registration_client.dart';

void main() {
  group('DatahubDeviceRegistrationClient.isDeviceRegistered', () {
    test('returns true on HTTP 200', () async {
      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/devices/name/');
          expect(request.url.queryParameters['device'], 'ABCD1234EF56');
          return http.Response('{"device":"ABCD1234EF56","device_name":"Badge 1"}', 200);
        }),
      );

      expect(await client.isDeviceRegistered('ABCD1234EF56'), isTrue);
    });

    test('returns false on HTTP 404', () async {
      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((_) async => http.Response('{"detail":"Device not found."}', 404)),
      );

      expect(await client.isDeviceRegistered('UNKNOWN'), isFalse);
    });
  });

  group('DatahubDeviceRegistrationClient.registerBadgeDevice', () {
    test('POSTs status payload with device block and api key', () async {
      final device = BleDevice(
        model: LDDeviceModel.badge,
        bleName: 'Luftdaten.at-Badge-ABCD1234EF56',
        bleMacAddress: 'ABCD1234EF56',
        deviceOriginalDisplayName: 'ABCD1234EF56',
      )
        ..apiKey = 'test-api-key-12345678'
        ..firmwareVersion = const FirmwareVersion(2, 1, 0);

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/devices/status/');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final deviceBlock = body['device'] as Map<String, dynamic>;
          expect(deviceBlock['device'], 'ABCD1234EF56');
          expect(deviceBlock['model'], LDDeviceModel.badge.id);
          expect(deviceBlock['apikey'], 'test-api-key-12345678');
          expect(deviceBlock['firmware'], '2.1.0');
          expect(body['status_list'], isNotEmpty);
          return http.Response('{"status":"success"}', 200);
        }),
      );

      expect(await client.registerBadgeDevice(device), DatahubRegisterResult.success);
    });

    test('POSTs with explicit apiKey override', () async {
      final device = BleDevice(
        model: LDDeviceModel.badge,
        bleName: 'Luftdaten.at-Badge-ABCD1234EF56',
        bleMacAddress: 'ABCD1234EF56',
        deviceOriginalDisplayName: 'ABCD1234EF56',
      );

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['device']['apikey'], 'explicit-override-key-123456');
          return http.Response('{"status":"success"}', 200);
        }),
      );

      expect(
        await client.registerBadgeDevice(
          device,
          apiKey: 'explicit-override-key-123456',
        ),
        DatahubRegisterResult.success,
      );
    });

    test('returns wrongApiKey on HTTP 400 Wrong API Key', () async {
      final device = BleDevice(
        model: LDDeviceModel.badge,
        bleName: 'Luftdaten.at-Badge-ABCD1234EF56',
        bleMacAddress: 'ABCD1234EF56',
        deviceOriginalDisplayName: 'ABCD1234EF56',
      )..apiKey = 'test-api-key-12345678';

      final client = DatahubDeviceRegistrationClient(
        serverHost: 'datahub.luftdaten.at',
        client: MockClient((_) async => http.Response('["Wrong API Key"]', 400)),
      );

      expect(
        await client.registerBadgeDevice(device),
        DatahubRegisterResult.wrongApiKey,
      );
    });

    test('returns false when api key is missing', () async {
      final device = BleDevice(
        model: LDDeviceModel.badge,
        bleName: 'Luftdaten.at-Badge-ABCD1234EF56',
        bleMacAddress: 'ABCD1234EF56',
        deviceOriginalDisplayName: 'ABCD1234EF56',
      );

      final client = DatahubDeviceRegistrationClient(
        client: MockClient((_) async => fail('should not send request')),
      );

      expect(await client.registerBadgeDevice(device), DatahubRegisterResult.failed);
    });
  });
}
