import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:i18n_extension/default.i18n.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/sd_ble_export.dart';
import 'package:luftdaten.at/features/devices/logic/sd_ble_import_storage.dart';
import 'package:luftdaten.at/features/measurements/logic/datahub_measurement_client.dart';

/// Confirms security copy, imports SD JSONL over BLE (`0x08`), saves locally, POSTs each line to Datahub.
Future<void> showAirStationSdBleImportFlow({
  required BuildContext context,
  required BleDevice device,
}) async {
  if (device.model != LDDeviceModel.station) return;
  if (device.state != BleDeviceState.connected) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Bluetooth zuerst verbinden.'.i18n)),
    );
    return;
  }

  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('SD-Daten importieren?'.i18n),
      content: SingleChildScrollView(
        child: Text(
          'Der Import liest gespeicherte Messwerte (JSONL) von der SD-Karte deiner '
                  'Air Station über Bluetooth. Nur im wifiless Modus mit Protokoll auf der '
                  'SD-Karte verfügbar.\n\n'
                  'Übertragung erfolgt hier unverschlüsselt wie bei BLE üblich — nutze wenn '
                  'möglich keine öffentliche Umgebung.\n\n'
                  'Danach werden die Rohzeilen lokal gespeichert und nacheinander an den '
                  'Luftdaten-Datahub gesendet.'
              .i18n,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Abbrechen'.i18n)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Import'.i18n)),
      ],
    ),
  );
  if (go != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Expanded(child: Text('Import über Bluetooth…'.i18n)),
        ],
      ),
    ),
  );

  SdBleImportResult result =
      SdBleImportResult.error('Import abgebrochen.');
  try {
    result = await getIt<BleController>().importSdJsonlFromBle(device);
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (!context.mounted) return;

  if (!result.ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.errorMessage ?? 'Import fehlgeschlagen.'.i18n)),
    );
    return;
  }

  if (result.lines.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Keine gültigen Messzeilen gefunden.'.i18n)),
    );
    return;
  }

  final rawLines =
      result.lines.map((m) => jsonEncode(m)).toList();
  try {
    await getIt<SdBleImportStorage>().appendBatch(
      bleName: device.bleName,
      rawJsonLines: rawLines,
    );
  } catch (e, st) {
    logger.d('SD import local save failed: $e $st');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lokales Speichern fehlgeschlagen: $e')),
    );
    return;
  }

  final client = getIt<DatahubMeasurementClient>();
  var uploadOk = 0;
  var uploadFail = 0;
  for (final m in result.lines) {
    try {
      final code = await client.postFirmwareStyleMeasurement(m);
      if (code == 200) {
        uploadOk++;
      } else {
        uploadFail++;
        logger.e('Datahub POST status $code');
      }
    } catch (e, st) {
      uploadFail++;
      logger.e('Datahub POST failed: $e');
      logger.d('$st');
    }
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Import: ${result.lines.length} Zeilen. '
                'Datahub: $uploadOk ok, $uploadFail Fehler.'
            .i18n,
      ),
    ),
  );
}
