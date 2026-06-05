import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';

/// Theme-based colors and labels for BLE connection state.
class DeviceConnectionAppearance {
  DeviceConnectionAppearance._();

  static Color statusColor(BuildContext context, BleDeviceState state) {
    final scheme = Theme.of(context).colorScheme;
    return switch (state) {
      BleDeviceState.connecting => scheme.tertiary,
      BleDeviceState.connected => scheme.primary,
      BleDeviceState.disconnected => scheme.error,
      BleDeviceState.discovered => scheme.secondary,
      BleDeviceState.notFound => scheme.outline,
      BleDeviceState.error => scheme.error,
      BleDeviceState.unknown => scheme.outline,
    };
  }

  static IconData bluetoothIcon(BleDeviceState state) {
    return switch (state) {
      BleDeviceState.discovered || BleDeviceState.disconnected => Icons.bluetooth,
      BleDeviceState.connecting => Icons.bluetooth_searching,
      BleDeviceState.connected => Icons.bluetooth_connected,
      _ => Icons.bluetooth_disabled_outlined,
    };
  }

  static String statusLabelKey(BleDeviceState state) {
    return switch (state) {
      BleDeviceState.connecting => 'Baue Verbindung auf...',
      BleDeviceState.connected => 'Verbunden',
      BleDeviceState.disconnected => 'Keine Verbindung',
      BleDeviceState.discovered => 'Sichtbar',
      BleDeviceState.notFound => 'Nicht in der Nähe',
      BleDeviceState.unknown => 'Nicht in der Nähe',
      BleDeviceState.error => 'Fehler',
    };
  }
}
