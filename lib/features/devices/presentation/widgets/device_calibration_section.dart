import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/sensor_calibration.dart';
import 'package:luftdaten.at/features/devices/data/sensor_details.dart';
import 'package:luftdaten.at/features/devices/logic/ble_calibration_backend.dart';
import 'package:luftdaten.at/features/devices/logic/device_calibration_store.dart';
import 'package:luftdaten.at/features/devices/logic/sensor_calibration_policy.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/co2_fresh_air_calibration_dialog.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/device_calibration_section.i18n.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';
import 'package:luftdaten.at/features/measurements/logic/thermal/body_heat_calibration.dart';

class DeviceCalibrationSection extends StatelessWidget {
  const DeviceCalibrationSection({
    super.key,
    required this.device,
    required this.isLoading,
    this.calibrationStore,
  });

  final BleDevice device;
  final bool isLoading;
  final DeviceCalibrationStore? calibrationStore;

  @override
  Widget build(BuildContext context) {
    if (isLoading ||
        device.state != BleDeviceState.connected ||
        device.availableSensors == null ||
        device.availableSensors!.isEmpty) {
      return const SizedBox.shrink();
    }

    final sensors = device.availableSensors!;
    final capabilities = SensorCalibrationPolicy.capabilitiesFor(sensors);
    if (capabilities.isEmpty) return const SizedBox.shrink();

    return ChangeNotifierBuilder(
      notifier: calibrationStore ?? getIt<DeviceCalibrationStore>(),
      builder: (context, store) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kalibrierung'.i18n,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Korrekturen werden in der App gespeichert und auf Live-Messungen angewendet.'.i18n,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 8),
              if (capabilities.contains(CalibrationCapability.co2FreshAir))
                _Co2CalibrationCard(device: device, sensors: sensors, store: store),
              if (capabilities.contains(CalibrationCapability.bodyHeat))
                const _BodyHeatCalibrationCard(),
              ..._climateOffsetCards(context, device, sensors, store),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _climateOffsetCards(
    BuildContext context,
    BleDevice device,
    List<SensorDetails> sensors,
    DeviceCalibrationStore store,
  ) {
    final cards = <Widget>[];
    final seen = <String>{};

    for (final item in SensorCalibrationPolicy.calibratableQuantities(sensors)) {
      if (item.capability == CalibrationCapability.co2FreshAir) continue;
      final key = deviceSensorOffsetKey(item.sensor, item.quantity);
      if (!seen.add(key)) continue;
      cards.add(
        _ClimateOffsetCard(
          device: device,
          sensor: item.sensor,
          quantity: item.quantity,
          store: store,
        ),
      );
    }
    return cards;
  }
}

class _Co2CalibrationCard extends StatelessWidget {
  const _Co2CalibrationCard({
    required this.device,
    required this.sensors,
    required this.store,
  });

  final BleDevice device;
  final List<SensorDetails> sensors;
  final DeviceCalibrationStore store;

  @override
  Widget build(BuildContext context) {
    final sensor = SensorCalibrationPolicy.co2SensorOnDevice(sensors);
    if (sensor == null) return const SizedBox.shrink();

    final offset = store.getOffset(device.bleName, sensor, MeasurableQuantity.co2);
    final backend = getIt.isRegistered<BleCalibrationBackend>()
        ? getIt<BleCalibrationBackend>()
        : DefaultBleCalibrationBackend();
    final firmwareSupported = backend.supportsForcedCo2Recal(sensor);

    return _CalibrationCard(
      title: 'CO₂ (Frischluft)'.i18n,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            offset != null
                ? 'Offset: %s ppm'.i18n.fill([offset.offset.toStringAsFixed(0)])
                : 'Kein Offset gesetzt'.i18n,
          ),
          if (!firmwareSupported)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Firmware-Neukalibrierung bald verfügbar'.i18n,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => showCo2FreshAirCalibrationDialog(
                  context,
                  device: device,
                  sensor: sensor,
                ),
                icon: const Icon(Icons.air, size: 18),
                label: Text('Frischluft-Kalibrierung'.i18n),
              ),
              if (offset != null)
                OutlinedButton(
                  onPressed: () => store.clearOffset(
                    device.bleName,
                    sensor,
                    MeasurableQuantity.co2,
                  ),
                  child: Text('Offset löschen'.i18n),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyHeatCalibrationCard extends StatefulWidget {
  const _BodyHeatCalibrationCard();

  @override
  State<_BodyHeatCalibrationCard> createState() => _BodyHeatCalibrationCardState();
}

class _BodyHeatCalibrationCardState extends State<_BodyHeatCalibrationCard> {
  @override
  Widget build(BuildContext context) {
    final store = BodyHeatCalibrationStore.instance;
    final result = store.delta(now: DateTime.now());

    final statusText = switch (result) {
      _ when result.isCalibrated => 'Qualität A (kalibriert)'.i18n,
      _ when result.usingFallback => 'Qualität B (Fallback)'.i18n,
      _ => 'Kalibrierung sammelt…'.i18n,
    };

    return _CalibrationCard(
      title: 'Körperwärme (UTCI)'.i18n,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Automatische Kalibrierung über Außen-Nachtmessungen.'.i18n),
          const SizedBox(height: 4),
          Text(
            'Proben: %s / %s'.i18n.fill([
              result.sampleCount,
              BodyHeatCalibrationStore.minSamples,
            ]),
          ),
          Text(
            result.deltaK != null
                ? 'ΔT_body: %s K'.i18n.fill([result.deltaK!.toStringAsFixed(2)])
                : 'Noch keine Kalibrierung'.i18n,
          ),
          Text(statusText),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              store.reset();
              setState(() {});
            },
            child: Text('Kalibrierung zurücksetzen'.i18n),
          ),
        ],
      ),
    );
  }
}

class _ClimateOffsetCard extends StatefulWidget {
  const _ClimateOffsetCard({
    required this.device,
    required this.sensor,
    required this.quantity,
    required this.store,
  });

  final BleDevice device;
  final LDSensor sensor;
  final MeasurableQuantity quantity;
  final DeviceCalibrationStore store;

  @override
  State<_ClimateOffsetCard> createState() => _ClimateOffsetCardState();
}

class _ClimateOffsetCardState extends State<_ClimateOffsetCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final existing = widget.store.getOffset(
      widget.device.bleName,
      widget.sensor,
      widget.quantity,
    );
    _controller = TextEditingController(
      text: existing != null ? existing.offset.toStringAsFixed(2) : '0',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTemp = widget.quantity == MeasurableQuantity.temperature;
    final title = isTemp
        ? 'Temperatur-Offset (%s)'.i18n.fill([widget.sensor.shortName])
        : 'Feuchte-Offset (%s)'.i18n.fill([widget.sensor.shortName]);
    final hint = isTemp ? 'Offset in °C'.i18n : 'Offset in % RH'.i18n;

    return _CalibrationCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(_controller.text.trim());
                  if (value == null) return;
                  if (value == 0) {
                    widget.store.clearOffset(
                      widget.device.bleName,
                      widget.sensor,
                      widget.quantity,
                    );
                    return;
                  }
                  widget.store.setOffset(
                    widget.device.bleName,
                    DeviceSensorOffset(
                      sensor: widget.sensor,
                      quantity: widget.quantity,
                      offset: value,
                      calibratedAt: DateTime.now(),
                    ),
                  );
                },
                child: Text('Speichern'.i18n),
              ),
              OutlinedButton(
                onPressed: () {
                  widget.store.clearOffset(
                    widget.device.bleName,
                    widget.sensor,
                    widget.quantity,
                  );
                  _controller.text = '0';
                },
                child: Text('Zurücksetzen'.i18n),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalibrationCard extends StatelessWidget {
  const _CalibrationCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
