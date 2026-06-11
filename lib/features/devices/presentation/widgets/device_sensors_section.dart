import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/sensor_details_dialog.dart';

import '../pages/device_detail_page.i18n.dart';

/// Inline sensor details for the device detail page.
class DeviceSensorsSection extends StatelessWidget {
  const DeviceSensorsSection({
    super.key,
    required this.device,
    required this.isLoading,
  });

  final BleDevice device;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sensoren'.i18n,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            _loadingRow()
          else if (device.state != BleDeviceState.connected)
            const SizedBox.shrink()
          else if (device.availableSensors == null || device.availableSensors!.isEmpty)
            Text(
              'Keine Sensorinformationen verfügbar'.i18n,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ..._sensorRows(context, device.availableSensors!),
        ],
      ),
    );
  }

  Widget _loadingRow() {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Sensoren werden geladen…'.i18n,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  List<Widget> _sensorRows(BuildContext context, List<SensorDetails> sensors) {
    return sensors.map((details) => _sensorCard(context, details)).toList();
  }

  Widget _sensorCard(BuildContext context, SensorDetails details) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.model.longName.i18n,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Misst: %s'.i18n.fill([
                      details.measuresQuantities.map((e) => e.name).join(', '),
                    ])),
                    if (details.serialNumber != null && details.serialNumber!.isNotEmpty)
                      Text('Seriennummer: %s'.i18n.fill([details.serialNumber!])),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Sensorinformationen'.i18n,
                onPressed: () => showSensorDetailsDialog(context, details),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
