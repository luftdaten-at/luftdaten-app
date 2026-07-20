import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_meas_log_export.dart';
import 'package:luftdaten.at/features/devices/logic/badge_meas_log_parser.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/badge_meas_log_ble_import.i18n.dart';
import 'package:luftdaten.at/features/measurements/logic/trip_controller.dart';

/// Confirms security copy, imports badge LDLG log over BLE, loads as Messreihe in Messwerte.
Future<void> showBadgeMeasLogBleImportFlow({
  required BuildContext context,
  required BleDevice device,
  required int recordCount,
}) async {
  if (device.model != LDDeviceModel.badge) return;
  if (device.state != BleDeviceState.connected) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Bluetooth zuerst verbinden.'.i18n)),
    );
    return;
  }
  if (device.isMeasLoggingActive) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Messmodus ist noch aktiv.'.i18n)),
    );
    return;
  }

  if (getIt.isRegistered<TripController>() &&
      getIt<TripController>().isOngoing &&
      getIt<TripController>().ongoingTrips.containsKey(device)) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Import während einer laufenden Messung nicht möglich.'.i18n)),
    );
    return;
  }

  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Messungen importieren?'.i18n),
      content: SingleChildScrollView(
        child: Text(
          'Der Import liest die offline gespeicherten Messungen deines Air Badge über Bluetooth (%s Datensätze).\n\n'
                  'Messmodus muss beendet sein. Übertragung erfolgt unverschlüsselt wie bei BLE üblich — nutze wenn '
                  'möglich keine öffentliche Umgebung.\n\n'
                  'Danach werden die Messungen als Messreihe in Messwerte geladen.'
              .i18n
              .fill([recordCount]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Abbrechen'.i18n)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Import'.i18n)),
      ],
    ),
  );
  if (go != true || !context.mounted) return;

  var cancelled = false;
  final progressNotifier = ValueNotifier(0);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) => ValueListenableBuilder<int>(
      valueListenable: progressNotifier,
      builder: (context, progressPct, _) {
        return AlertDialog(
          title: Text('Messungen werden über Bluetooth geladen…'.i18n),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progressPct <= 0 ? null : progressPct / 100),
              const SizedBox(height: 12),
              Text('$progressPct %'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.pop(ctx);
              },
              child: Text('Abbrechen'.i18n),
            ),
          ],
        );
      },
    ),
  );

  final controller = getIt<BleController>();
  final result = await controller.importBadgeMeasLogFromBle(
    device,
    onProgress: (BadgeMeasLogExportProgress progress) {
      progressNotifier.value = progress.progressPct;
    },
    shouldCancel: () async => cancelled,
  );

  progressNotifier.dispose();

  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
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

  final trip = badgeMeasLogLinesToTrip(lines: result.lines, device: device);
  if (trip == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Keine gültigen Messzeilen gefunden.'.i18n)),
    );
    return;
  }

  if (!getIt.isRegistered<TripController>()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import fehlgeschlagen: Messwerte nicht verfügbar.'.i18n)),
    );
    return;
  }

  await getIt<TripController>().addImportedTrip(trip);
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '%s Messpunkte importiert — in Messwerte anzeigen.'.i18n.fill([trip.data.length]),
      ),
    ),
  );

  final erase = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Messungen auf dem Badge löschen?'.i18n),
      content: Text(
        'Die Messungen wurden in Messwerte geladen. Sollen sie auch vom Badge gelöscht werden?'.i18n,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Behalten'.i18n)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Löschen'.i18n)),
      ],
    ),
  );
  if (erase != true || !context.mounted) return;

  final erased = await controller.eraseBadgeMeasLog(device);
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        erased
            ? 'Messungen auf dem Badge gelöscht.'.i18n
            : 'Messungen konnten auf dem Badge nicht gelöscht werden.'.i18n,
      ),
    ),
  );
}
