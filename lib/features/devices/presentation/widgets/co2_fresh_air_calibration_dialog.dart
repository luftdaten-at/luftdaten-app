import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/sensor_calibration.dart';
import 'package:luftdaten.at/features/devices/logic/ble_controller.dart';
import 'package:luftdaten.at/features/devices/logic/device_calibration_store.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_calibration_section.i18n.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

const _defaultReferenceCo2Ppm = 420.0;

Future<void> showCo2FreshAirCalibrationDialog(
  BuildContext context, {
  required BleDevice device,
  required LDSensor sensor,
}) {
  final bodyKey = GlobalKey<_Co2FreshAirCalibrationDialogBodyState>();

  return showLDDialog(
    context,
    title: 'CO₂-Frischluft-Kalibrierung'.i18n,
    icon: Icons.air,
    content: _Co2FreshAirCalibrationDialogBody(
      key: bodyKey,
      device: device,
      sensor: sensor,
    ),
    actions: [
      LDDialogAction.cancel(),
      LDDialogAction.save(
        onTap: () => bodyKey.currentState?.saveOffset(),
      ),
    ],
  );
}

class _Co2FreshAirCalibrationDialogBody extends StatefulWidget {
  const _Co2FreshAirCalibrationDialogBody({
    super.key,
    required this.device,
    required this.sensor,
  });

  final BleDevice device;
  final LDSensor sensor;

  @override
  State<_Co2FreshAirCalibrationDialogBody> createState() =>
      _Co2FreshAirCalibrationDialogBodyState();
}

class _Co2FreshAirCalibrationDialogBodyState
    extends State<_Co2FreshAirCalibrationDialogBody> {
  final _targetController = TextEditingController(text: '420');
  var _measuring = false;
  double? _rawCo2;
  String? _errorMessage;

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  double? get _targetPpm =>
      double.tryParse(_targetController.text.trim()) ?? _defaultReferenceCo2Ppm;

  double? get _computedOffset {
    final raw = _rawCo2;
    final target = _targetPpm;
    if (raw == null || target == null) return null;
    return target - raw;
  }

  bool get canSave => _rawCo2 != null && _computedOffset != null;

  void saveOffset() {
    final raw = _rawCo2;
    final offset = _computedOffset;
    final target = _targetPpm;
    if (raw == null || offset == null || target == null) return;

    getIt<DeviceCalibrationStore>().setOffset(
      widget.device.bleName,
      DeviceSensorOffset(
        sensor: widget.sensor,
        quantity: MeasurableQuantity.co2,
        offset: offset,
        calibratedAt: DateTime.now(),
        note: 'fresh_air',
        rawAtCalibration: raw,
        targetAtCalibration: target,
      ),
    );
  }

  Future<void> _measure() async {
    setState(() {
      _measuring = true;
      _errorMessage = null;
      _rawCo2 = null;
    });

    try {
      final result = await getIt<BleController>().readSensorValues(widget.device);
      final points = List<SensorDataPoint>.from(result.first as List);
      final corrected = points
          .where((p) => p.sensor == widget.sensor)
          .map((p) => p.values[MeasurableQuantity.co2])
          .whereType<double>()
          .firstOrNull;
      if (corrected == null) {
        setState(() {
          _errorMessage = 'Kein CO₂-Wert vom Gerät empfangen.'.i18n;
        });
        return;
      }

      final existing = getIt<DeviceCalibrationStore>().getOffset(
        widget.device.bleName,
        widget.sensor,
        MeasurableQuantity.co2,
      );
      final raw = corrected - (existing?.offset ?? 0);

      setState(() => _rawCo2 = raw);
    } catch (e) {
      setState(() {
        _errorMessage = 'Messung fehlgeschlagen: %s'.i18n.fill([e]);
      });
    } finally {
      setState(() => _measuring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offset = _computedOffset;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stelle das Gerät in gut belüftete Frischluft (idealerweise im Freien) und warte, bis der CO₂-Wert stabil ist.'
                .i18n,
          ),
          const SizedBox(height: 12),
          Text(
            'App-seitige Korrektur — ersetzt keine sensorinterne Forced Recalibration.'.i18n,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Referenz-CO₂ (ppm)'.i18n,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_rawCo2 != null) ...[
            Text('Gemessener CO₂-Wert: %s ppm'.i18n.fill([_rawCo2!.toStringAsFixed(0)])),
            if (offset != null)
              Text('Offset %s ppm wird angewendet.'.i18n.fill([offset.toStringAsFixed(0)])),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _measuring ? null : _measure,
            icon: _measuring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sensors),
            label: Text('Messung starten'.i18n),
          ),
        ],
      ),
    );
  }
}
