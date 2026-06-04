import 'package:luftdaten.at/features/devices/data/battery_details.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/device_error.dart';

/// Wi‑Fi detail byte (index 3) when [BleOperationalStatusFlags.wifiFailure] is set.
enum BleWifiDetailCode {
  ok(0),
  credentialsNotConfigured(0x01),
  ssidNotInScan(0x02),
  connectionFailed(0x03);

  const BleWifiDetailCode(this.value);
  final int value;

  static BleWifiDetailCode fromByte(int b) {
    for (final c in BleWifiDetailCode.values) {
      if (c.value == b) return c;
    }
    return BleWifiDetailCode.ok;
  }
}

/// Operational flags byte (index 4) — firmware [BleOperationalStatusFlags].
class BleOperationalStatusFlags {
  BleOperationalStatusFlags(this.raw);

  final int raw;

  static const int configIncomplete = 0x01;
  static const int wifiFailure = 0x02;
  static const int noSensor = 0x04;
  static const int ssidConfigured = 0x08;

  factory BleOperationalStatusFlags.fromByte(int b) => BleOperationalStatusFlags(b);

  bool get hasConfigIncomplete => (raw & configIncomplete) != 0;
  bool get hasWifiFailure => (raw & wifiFailure) != 0;
  bool get hasNoSensor => (raw & noSensor) != 0;
  bool get hasSsidConfigured => (raw & ssidConfigured) != 0;
}

enum BleNoticeSeverity { warning, error }

/// Stable id for i18n lookup in [BleDeviceNoticesBanner].
class BleDeviceNotice {
  const BleDeviceNotice({required this.id, required this.severity});

  final String id;
  final BleNoticeSeverity severity;
}

class BleDeviceStatusParseResult {
  const BleDeviceStatusParseResult({required this.battery, required this.notices});

  final BatteryDetails battery;
  final List<BleDeviceNotice> notices;
}

class BleDeviceStatusParser {
  BleDeviceStatusParser._();

  static BleDeviceStatusParseResult parse(List<int> raw) {
    if (raw.length < 3) {
      return BleDeviceStatusParseResult(
        battery: BatteryDetails(status: BatteryStatus.faulty),
        notices: const [],
      );
    }

    final battery = BatteryDetails.fromBytes(raw.sublist(0, 3));
    if (raw.length < 5) {
      return BleDeviceStatusParseResult(battery: battery, notices: const []);
    }

    final wifiDetail = BleWifiDetailCode.fromByte(raw[3]);
    final flags = BleOperationalStatusFlags.fromByte(raw[4]);
    final notices = _noticesFromFlags(flags, wifiDetail);
    return BleDeviceStatusParseResult(battery: battery, notices: notices);
  }

  static List<BleDeviceNotice> _noticesFromFlags(
    BleOperationalStatusFlags flags,
    BleWifiDetailCode wifiDetail,
  ) {
    final notices = <BleDeviceNotice>[];

    if (flags.hasConfigIncomplete) {
      notices.add(const BleDeviceNotice(
        id: 'config_incomplete',
        severity: BleNoticeSeverity.warning,
      ));
    }

    if (flags.hasWifiFailure) {
      final wifiId = switch (wifiDetail) {
        BleWifiDetailCode.credentialsNotConfigured => 'wifi_credentials_missing',
        BleWifiDetailCode.ssidNotInScan => 'wifi_ssid_not_found',
        BleWifiDetailCode.connectionFailed => 'wifi_connection_failed',
        BleWifiDetailCode.ok => 'wifi_failure',
      };
      notices.add(BleDeviceNotice(id: wifiId, severity: BleNoticeSeverity.error));
    }

    if (flags.hasNoSensor) {
      notices.add(const BleDeviceNotice(
        id: 'no_sensor',
        severity: BleNoticeSeverity.error,
      ));
    }

    return notices;
  }

  /// Adds [no_sensor] when connect-time [SensorNotFoundError] exists but flags did not report it.
  static List<BleDeviceNotice> mergeConnectErrors(
    List<BleDeviceNotice> notices,
    List<DeviceError> errors,
  ) {
    if (notices.any((n) => n.id == 'no_sensor')) return notices;
    if (!errors.any((e) => e is SensorNotFoundError)) return notices;
    return [
      ...notices,
      const BleDeviceNotice(id: 'no_sensor', severity: BleNoticeSeverity.error),
    ];
  }
}

/// Applies full `device_status` payload to [device] (battery + operational notices).
void applyDeviceStatusBytes(BleDevice device, List<int> raw) {
  final parsed = BleDeviceStatusParser.parse(raw);
  device.batteryDetails = parsed.battery;
  device.operationalNotices = BleDeviceStatusParser.mergeConnectErrors(
    parsed.notices,
    device.errors,
  );
}
