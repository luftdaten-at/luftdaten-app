import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/di/di.dart';
import 'package:luftdaten.at/features/devices/logic/battery_info_aggregator.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/device_manager.dart';
import 'package:luftdaten.at/features/devices/presentation/pages/device_manager_page.dart';
import 'package:provider/provider.dart';

bool _harnessInitialized = false;
final Set<String> _initializedStorageBuckets = {};

String _testStorageRoot() {
  final dir = Directory('/tmp/luftdaten_tests_${Isolate.current.hashCode}');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir.path;
}

/// One-time setup: path_provider mock, BLE plugin mock, and i18n silence callbacks.
void initDeviceWidgetTestHarness() {
  if (_harnessInitialized) return;
  _harnessInitialized = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
    final root = _testStorageRoot();
    if (methodCall.method == 'getApplicationDocumentsDirectory') return root;
    if (methodCall.method == 'getTemporaryDirectory') return root;
    return null;
  });

  const bleChannel = MethodChannel('flutter_reactive_ble_method');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(bleChannel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'initialize':
        return null;
      case 'getState':
        return 'PoweredOn';
      default:
        return null;
    }
  });

  Translations.missingKeyCallback = (_, __) {};
  Translations.missingTranslationCallback = ({
    required key,
    required locale,
    required translations,
    required supportedLocales,
  }) =>
      false;
}

Future<void> _ensureStorageBucket(String bucket) async {
  if (_initializedStorageBuckets.contains(bucket)) return;
  await GetStorage.init(bucket);
  _initializedStorageBuckets.add(bucket);
}

/// Registers getIt services used by device presentation widgets.
Future<void> setUpDeviceWidgetTests({
  String storageBucket = 'device_widget_tests',
  bool registerBleController = false,
  bool mockBleEnabled = false,
}) async {
  initDeviceWidgetTestHarness();
  for (final bucket in ['settings', storageBucket, 'devices']) {
    await _ensureStorageBucket(bucket);
  }
  GetIt.instance.reset();
  getIt.registerSingleton<DeviceManager>(DeviceManager());
  getIt.registerSingleton<BatteryInfoAggregator>(BatteryInfoAggregator());
  if (registerBleController) {
    getIt.registerSingleton<BleController>(BleController());
  }
  AppSettings.I.setMockBleDevicesEnabledForTests(mockBleEnabled);
  DeviceManagerPage.resetForTests();
}

void tearDownDeviceWidgetTests() {
  DeviceManagerPage.resetForTests();
  GetIt.instance.reset();
}

Widget buildDeviceTestApp(
  Widget child, {
  DeviceManager? manager,
}) {
  final deviceManager = manager ?? getIt<DeviceManager>();
  return I18n(
    initialLocale: const Locale('de'),
    child: ChangeNotifierProvider<DeviceManager>.value(
      value: deviceManager,
      child: MaterialApp(home: child),
    ),
  );
}

Future<void> pumpDeviceApp(
  WidgetTester tester,
  Widget child, {
  DeviceManager? manager,
}) async {
  await tester.pumpWidget(buildDeviceTestApp(child, manager: manager));
}
