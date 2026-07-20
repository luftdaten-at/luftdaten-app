import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_meas_log_parser.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/badge_meas_log_ble_import.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/badge_meas_log_list_dialog.i18n.dart';

Future<void> showBadgeMeasLogListDialog({
  required BuildContext context,
  required BleDevice device,
  required int recordCount,
  Future<void> Function()? onImportComplete,
}) async {
  if (recordCount <= 0) return;

  final times = badgeMeasLogEstimatedRecordTimes(recordCount: recordCount);
  final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Messungen'.i18n),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Geschätzte Zeitpunkte (30-Sekunden-Intervall).'.i18n,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: recordCount,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final listIndex = recordCount - 1 - index;
                  final time = times[listIndex].toLocal();
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${listIndex + 1}', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text('Messung %s'.i18n.fill(['${listIndex + 1}'])),
                    subtitle: Text(dateFormat.format(time)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await showBadgeMeasLogBleImportFlow(
                  context: context,
                  device: device,
                  recordCount: recordCount,
                );
                await onImportComplete?.call();
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: Text('Messungen importieren'.i18n),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Schließen'.i18n),
        ),
      ],
    ),
  );
}
