import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_store.dart';
import 'package:luftdaten.at/features/devices/logic/device_config_sync.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_profile.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_info_section.dart';

import '../../../../test_helpers/device_widget_test_harness.dart';

void main() {
  setUp(() async => setUpDeviceWidgetTests(
        storageBucket: 'device_info_section_tests',
        mockBleEnabled: true,
      ));

  tearDown(tearDownDeviceWidgetTests);

  testWidgets('loading state shows spinner and loading text', (tester) async {
    final device = BleDevice(
      model: LDDeviceModel.aRound,
      bleName: 'Luftdaten.at-000000000001',
      bleMacAddress: '000000000001',
      deviceOriginalDisplayName: 'Air aRound 1',
    );

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceInfoSection(
          device: device,
          isStation: false,
          isLoading: true,
        ),
      ),
    );

    expect(find.text('Geräteinfo'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Geräteinfo wird geladen'), findsOneWidget);
  });

  testWidgets('disconnected shows availability hint', (tester) async {
    final device = BleDevice(
      model: LDDeviceModel.aRound,
      bleName: 'Luftdaten.at-000000000002',
      bleMacAddress: '000000000002',
      deviceOriginalDisplayName: 'Air aRound 2',
    );

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceInfoSection(
          device: device,
          isStation: false,
          isLoading: false,
        ),
      ),
    );

    expect(find.textContaining('nach der Verbindung verfügbar'), findsOneWidget);
  });

  testWidgets('connected portable shows firmware and metadata', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceInfoSection(
          device: device,
          isStation: false,
          isLoading: false,
        ),
      ),
    );

    expect(find.textContaining('Firmware-Version:'), findsOneWidget);
    expect(find.textContaining('1.0.0'), findsOneWidget);
    expect(find.textContaining('Name:'), findsOneWidget);
    expect(find.textContaining('Adresse:'), findsOneWidget);
    expect(find.textContaining('Status:'), findsOneWidget);
  });

  testWidgets('connected station shows firmware and sensor id', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceInfoSection(
          device: device,
          isStation: true,
          isLoading: false,
        ),
      ),
    );

    expect(find.textContaining('Firmware-Version:'), findsOneWidget);
    expect(find.text('Gerät: '), findsOneWidget);
    expect(find.textContaining('Sensor-ID:'), findsOneWidget);
  });

  testWidgets('connected station shows config summary and sync badge', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;

    final config = AirStationConfig(
      id: device.bleName,
      autoUpdateMode: AutoUpdateMode.on,
      batterySaverMode: BatterySaverMode.normal,
      measurementInterval: AirStationMeasurementInterval.min5,
      longitude: null,
      latitude: null,
      height: null,
      deviceId: 'test-device-id',
    );

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceInfoSection(
          device: device,
          isStation: true,
          isLoading: false,
          configSyncResult: DeviceConfigSyncResult(
            status: DeviceConfigSyncStatus.inSync,
            localRecord: StationConfigRecord(
              config: config,
              lastConfiguredAt: DateTime(2026, 5, 31, 12, 0),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Konfiguration'), findsOneWidget);
    expect(find.textContaining('Konfiguration aktuell'), findsOneWidget);
    expect(find.textContaining('test-device-id'), findsOneWidget);
    expect(find.textContaining('Zuletzt konfiguriert'), findsOneWidget);
  });

  testWidgets('connected portable shows app-only config badge', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.aRound,
      existingBleNames: const [],
    );
    device.state = BleDeviceState.connected;

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceInfoSection(
          device: device,
          isStation: false,
          isLoading: false,
          configSyncResult: DeviceConfigSyncResult(
            status: DeviceConfigSyncStatus.localOnly,
            portableRecord: PortableDeviceConfig(
              bleName: device.bleName,
              measurementInterval: 10,
              autoReconnect: true,
              lastConfiguredAt: DateTime(2026, 5, 31, 9, 0),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Nur App-Einstellung'), findsOneWidget);
    expect(find.textContaining('Messintervall (App)'), findsOneWidget);
  });

  testWidgets('station shows stored wifi ssid and password hint without password', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceInfoSection(
          device: device,
          isStation: true,
          isLoading: false,
          wifiSsid: 'Mein-WLAN',
          wifiPasswordStored: true,
        ),
      ),
    );

    expect(find.textContaining('WLAN SSID:'), findsOneWidget);
    expect(find.textContaining('Mein-WLAN'), findsOneWidget);
    expect(find.textContaining('WLAN Passwort:'), findsOneWidget);
    expect(find.textContaining('Gespeichert'), findsOneWidget);
    expect(find.textContaining('Mein-WLAN-Passwort'), findsNothing);
  });

  testWidgets('connected station shows live ssid configured on device', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;
    device.wifiSsidConfiguredOnDevice = true;

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceInfoSection(
          device: device,
          isStation: true,
          isLoading: false,
          wifiSsid: 'Mein-WLAN',
          wifiPasswordStored: true,
        ),
      ),
    );

    expect(find.textContaining('WLAN auf Gerät:'), findsOneWidget);
    expect(find.textContaining('SSID konfiguriert'), findsOneWidget);
  });

  testWidgets('connected station shows live wifi error from operational notices', (tester) async {
    final device = MockBleDevices.buildMockDevice(
      LDDeviceModel.station,
      existingBleNames: const [],
    );
    MockBleProfile.apply(device);
    device.state = BleDeviceState.connected;
    device.operationalNotices = const [
      BleDeviceNotice(id: 'wifi_ssid_not_found', severity: BleNoticeSeverity.error),
    ];

    await pumpDeviceApp(
      tester,
      Scaffold(
        body: DeviceInfoSection(
          device: device,
          isStation: true,
          isLoading: false,
        ),
      ),
    );

    expect(find.textContaining('WLAN auf Gerät:'), findsOneWidget);
    expect(find.textContaining('SSID nicht gefunden'), findsOneWidget);
  });
}
