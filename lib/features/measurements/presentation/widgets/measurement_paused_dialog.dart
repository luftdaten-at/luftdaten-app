import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/measurements/presentation/widgets/measurement_paused_dialog.i18n.dart';

/// Non-dismissible dialog shown while a trip is paused for BLE disconnect.
Future<void> showMeasurementPausedDialog(
  BuildContext context, {
  required VoidCallback onStopMeasurement,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Theme(
      data: Theme.of(dialogContext).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
      ),
      child: AlertDialog(
        icon: Icon(Icons.bluetooth_disabled, color: Theme.of(dialogContext).primaryColor),
        title: Text('Messung pausiert'.i18n),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Die Bluetooth-Verbindung zum Messgerät wurde unterbrochen. '
                      'Die Messung ist pausiert — es wird versucht, die Verbindung wiederherzustellen.'
                  .i18n,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: onStopMeasurement,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                Theme.of(dialogContext).primaryColor,
              ),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ),
            child: Text('Messung beenden'.i18n),
          ),
        ],
      ),
    ),
  );
}
