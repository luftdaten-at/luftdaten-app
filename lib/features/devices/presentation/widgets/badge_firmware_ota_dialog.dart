import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_firmware_image.dart';
import 'package:luftdaten.at/features/devices/logic/badge_firmware_release.dart';
import 'package:luftdaten.at/features/devices/logic/ble_ota.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_devices.dart';
import 'package:luftdaten.at/features/devices/logic/mock_ble_gatt.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/badge_firmware_ota_dialog.i18n.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';

enum _BadgeOtaSource { github, file }

/// Badge-only BLE OTA entry: GitHub release download or local `.bin` file picker.
Future<void> showBadgeFirmwareOtaFlow({
  required BuildContext context,
  required BleDevice device,
}) async {
  if (device.model != LDDeviceModel.badge) return;
  if (device.state != BleDeviceState.connected) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Bluetooth zuerst verbinden.'.i18n)),
    );
    return;
  }

  if (getIt.isRegistered<TripController>() &&
      getIt<TripController>().isOngoing &&
      getIt<TripController>().ongoingTrips.containsKey(device)) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('Firmware-Update während einer laufenden Messung nicht möglich.'.i18n),
      ),
    );
    return;
  }

  final source = await showDialog<_BadgeOtaSource>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Firmware aktualisieren'.i18n),
      content: Text('Installierte Version: ${device.firmwareVersion ?? 'unbekannt'}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Abbrechen'.i18n)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _BadgeOtaSource.file),
          child: Text('Datei wählen'.i18n),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _BadgeOtaSource.github),
          child: Text('Von GitHub laden'.i18n),
        ),
      ],
    ),
  );
  if (source == null || !context.mounted) return;

  BadgeFirmwareImage? image;
  try {
    switch (source) {
      case _BadgeOtaSource.github:
        image = await _loadFromGitHub(context, device);
      case _BadgeOtaSource.file:
        image = await _loadFromFilePicker(context, device);
    }
  } on BadgeFirmwareReleaseException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
    return;
  }

  if (image == null || !context.mounted) return;

  if (!BadgeFirmwareImage.isUpgradeFrom(
    current: device.firmwareVersion,
    target: image.targetVersion,
  )) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Die gewählte Version ist nicht neuer als die installierte.'.i18n)),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Update starten?'.i18n),
      content: Text(
        'Aktuell: ${device.firmwareVersion}\n'
        'Neu: ${image!.targetVersion}\n\n'
        'Das Gerät startet nach dem Update neu. Nicht trennen.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Abbrechen'.i18n)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Update starten'.i18n)),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await _runOtaTransfer(context: context, device: device, image: image);
}

Future<BadgeFirmwareImage?> _loadFromGitHub(
  BuildContext context,
  BleDevice device,
) async {
  if (!context.mounted) return null;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Expanded(child: Text('Release wird geladen…'.i18n)),
        ],
      ),
    ),
  );

  BadgeFirmwareImage? image;
  try {
    final client = BadgeFirmwareReleaseClient();
    final release = await client.fetchLatest();
    if (release == null) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kein Firmware-Release verfügbar.'.i18n)),
        );
      }
      return null;
    }
    if (!BadgeFirmwareImage.isUpgradeFrom(
      current: device.firmwareVersion,
      target: release.version,
    )) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kein neueres Release auf GitHub (%s).'.i18n.fill([release.version]))),
        );
      }
      return null;
    }
    image = await client.download(release);
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
  return image;
}

Future<BadgeFirmwareImage?> _loadFromFilePicker(
  BuildContext context,
  BleDevice device,
) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['bin'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  Uint8List? bytes;
  if (file.bytes != null) {
    bytes = file.bytes!;
  } else if (file.path != null) {
    bytes = await File(file.path!).readAsBytes();
  }
  if (bytes == null || bytes.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firmware-Datei konnte nicht gelesen werden.'.i18n)),
      );
    }
    return null;
  }

  var version = parseFirmwareVersionFromFilename(file.name);
  if (version == null && file.path != null) {
    version = parseFirmwareVersionFromFilename(file.path!);
  }
  if (version == null && context.mounted) {
    version = await _promptFirmwareVersion(context);
  }
  if (version == null) return null;

  return BadgeFirmwareImage(bytes: bytes, targetVersion: version);
}

Future<FirmwareVersion?> _promptFirmwareVersion(BuildContext context) async {
  final majorCtrl = TextEditingController();
  final minorCtrl = TextEditingController();
  final patchCtrl = TextEditingController(text: '0');

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Firmware-Version'.i18n),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Versionsnummer der gewählten Datei eingeben.'.i18n),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: majorCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Major'.i18n),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: minorCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Minor'.i18n),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: patchCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Patch'.i18n),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Abbrechen'.i18n)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('OK'.i18n)),
      ],
    ),
  );

  if (ok != true) return null;
  final major = int.tryParse(majorCtrl.text.trim());
  final minor = int.tryParse(minorCtrl.text.trim());
  final patch = int.tryParse(patchCtrl.text.trim()) ?? 0;
  if (major == null || minor == null) return null;
  return FirmwareVersion(major, minor, patch);
}

Future<void> _runOtaTransfer({
  required BuildContext context,
  required BleDevice device,
  required BadgeFirmwareImage image,
}) async {
  final progress = ValueNotifier<int>(0);
  var cancelRequested = false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) => ValueListenableBuilder<int>(
      valueListenable: progress,
      builder: (context, pct, _) {
        return AlertDialog(
          title: Text('Firmware wird übertragen…'.i18n),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: pct / 100),
              const SizedBox(height: 12),
              Text('$pct %'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelRequested = true;
                Navigator.pop(ctx);
              },
              child: Text('Abbrechen'.i18n),
            ),
          ],
        );
      },
    ),
  );

  BleOtaResult result = BleOtaResult.failure('Unbekannter Fehler');
  try {
    final client = BleOtaClient(
      transport: MockBleDevices.canUseMockBle(device)
          ? MockBleGattTransport.instance
          : null,
    );
    result = await client.performUpdate(
      device: device,
      image: image,
      onProgress: (p) => progress.value = p.progressPct,
      shouldCancel: () async => cancelRequested,
    );
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    progress.dispose();
  }

  if (!context.mounted) return;

  if (result.ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Firmware aktualisiert (%s).'.i18n.fill([result.confirmedVersion.toString()]),
        ),
      ),
    );
    return;
  }

  if (result.cancelled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Firmware-Update abgebrochen.'.i18n)),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result.errorMessage ?? 'Firmware-Update fehlgeschlagen.'.i18n)),
  );
}
