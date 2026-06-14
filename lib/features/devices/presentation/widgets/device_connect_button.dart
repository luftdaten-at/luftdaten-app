import 'package:flutter/material.dart';
import 'package:i18n_extension/default.i18n.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';

class DeviceConnectButton extends StatefulWidget {
  const DeviceConnectButton({super.key, required this.device, this.onSelected});

  final BleDevice device;
  final void Function(BleDevice)? onSelected;

  @override
  State<DeviceConnectButton> createState() => _DeviceConnectButtonState();
}

class _DeviceConnectButtonState extends State<DeviceConnectButton> {
  @override
  void initState() {
    widget.device.addListener(setStateCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.device.state) {
      case BleDeviceState.discovered:
      case BleDeviceState.disconnected:
      case BleDeviceState.notFound:
      case BleDeviceState.unknown:
        return FilledButton(
          onPressed: widget.onSelected != null ? _connectAndSelect : () => widget.device.connect(),
          child: Text('Verbinden'.i18n),
        );
      case BleDeviceState.connecting:
        return FilledButton(
          onPressed: null,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.grey.shade300),
          ),
          child: Text('Wird verbunden...'.i18n),
        );
      case BleDeviceState.connected:
        if(widget.onSelected != null) {
          return FilledButton(
            onPressed: () => widget.onSelected!(widget.device),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.green),
            ),
            child: Text('Auswählen'.i18n),
          );
        }
        return FilledButton(
          onPressed: () => widget.device.disconnect(),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.red),
          ),
          child: Text('Trennen'.i18n),
        );
      case BleDeviceState.error:
        return FilledButton(
          onPressed: widget.onSelected != null ? _connectAndSelect : () => widget.device.connect(),
          child: Text('Verbinden'.i18n),
        );
    }
  }

  Future<void> _connectAndSelect() async {
    final success = await widget.device.connect();
    if (!mounted || !success || widget.onSelected == null) return;
    widget.onSelected!(widget.device);
  }

  void setStateCallback() => setState(() {});

  @override
  void dispose() {
    widget.device.removeListener(setStateCallback);
    super.dispose();
  }
}
