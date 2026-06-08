import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:luftdaten.at/core/utils/util.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/data/ble_device_status.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

/// Firmware-aligned byte encoders for mock GATT characteristics.
abstract final class MockBleGattCodec {
  static const int cmdReadSensorData = 0x01;
  static const int cmdReadSensorDataAndBattery = 0x02;
  static const int cmdSetAirStationConfiguration = 0x06;

  static List<int> encodeDeviceInfoJson(BleDevice device) {
    final payload = <String, dynamic>{
      'device': {
        'firmware': '1.0.0',
        'device': device.chipIdForApi,
        'model': device.model.name,
      },
      'sensor_list': [
        {
          'model': LDSensor.sen5x.id,
          'dimensions': LDSensor.sen5x.measures.map((q) => q.id).toList(),
          'serial': 'MOCK-SEN5X',
        },
      ],
    };
    return utf8.encode(jsonEncode(payload));
  }

  static List<int> encodeSensorInfo() {
    final serial = utf8.encode('MOCK-SEN5X');
    final details = <int>[1, 0, 1, 0, 1, 0, ...serial];
    return [LDSensor.sen5x.id, 0xFF, ...details, 0xFF];
  }

  static List<int> encodeDeviceStatus({
    required double batteryPct,
    required int operationalFlags,
    int wifiDetail = 0,
  }) {
    final pct = batteryPct.round().clamp(0, 100);
    final voltageTimes10 = (37 + pct / 2).round().clamp(0, 255);
    return [1, pct, voltageTimes10, wifiDetail, operationalFlags & 0xFF];
  }

  static Map<MeasurableQuantity, double> telemetryValues({double? timeSeconds}) {
    final t = timeSeconds ?? DateTime.now().millisecondsSinceEpoch / 1000.0;
    final pm25 = 12 + 8 * sin(t / 30);
    return {
      MeasurableQuantity.pm25: pm25,
      MeasurableQuantity.pm10: pm25 * 1.2,
      MeasurableQuantity.pm1: pm25 * 0.8,
      MeasurableQuantity.pm4: pm25 * 1.1,
      MeasurableQuantity.temperature: 21 + 2 * sin(t / 120),
      MeasurableQuantity.humidity: 45 + 5 * cos(t / 90),
      MeasurableQuantity.voc: 120 + 30 * sin(t / 45),
    };
  }

  static List<int> encodeSensorValuesBinary(Map<MeasurableQuantity, double> values) {
    final entries = values.entries.toList();
    final out = <int>[LDSensor.sen5x.id, entries.length];
    for (final entry in entries) {
      final scaled = (entry.value * 10).round().clamp(0, 0xFFFF);
      out
        ..add(entry.key.id)
        ..add((scaled >> 8) & 0xFF)
        ..add(scaled & 0xFF);
    }
    return out;
  }

  /// Inverse of [encodeSensorValuesBinary] for tests and validation.
  static Map<MeasurableQuantity, double> decodeSensorValuesBinary(List<int> raw) {
    if (raw.length < 2) return {};
    final count = raw[1];
    final out = <MeasurableQuantity, double>{};
    var offset = 2;
    for (var i = 0; i < count; i++) {
      if (offset + 3 > raw.length) break;
      final quantity = MeasurableQuantity.fromId(raw[offset]);
      final scaled = (raw[offset + 1] << 8) | raw[offset + 2];
      out[quantity] = scaled / 10.0;
      offset += 3;
    }
    return out;
  }

  /// Read-back TLV for `air_station_configuration` (no leading `0x06`, no secrets).
  static List<int> encodeAirStationConfigReadBack(AirStationConfig config) {
    final out = <int>[];

    void appendInt32Tlv(int flag, int value) {
      out
        ..add(flag)
        ..add(4)
        ..addAll(Util.toByteArray(value));
    }

    void appendUtf8Tlv(int flag, String s) {
      final utf = utf8.encode(s);
      if (utf.isEmpty) return;
      if (utf.length > 255) {
        throw FormatException('TLV UTF-8 value for flag $flag exceeds 255 bytes');
      }
      out
        ..add(flag)
        ..add(utf.length)
        ..addAll(utf);
    }

    appendInt32Tlv(AirStationConfigFlags.AUTO_UPDATE_MODE.value, config.autoUpdateMode.encoded);
    appendInt32Tlv(AirStationConfigFlags.BATTERY_SAVE_MODE.value, config.batterySaverMode.encoded);
    appendInt32Tlv(
      AirStationConfigFlags.MEASUREMENT_INTERVAL.value,
      config.measurementInterval.seconds,
    );
    appendUtf8Tlv(AirStationConfigFlags.LONGITUDE.value, config.longitude?.toString() ?? '');
    appendUtf8Tlv(AirStationConfigFlags.LATITUDE.value, config.latitude?.toString() ?? '');
    appendUtf8Tlv(AirStationConfigFlags.HEIGHT.value, config.height?.toString() ?? '');

    final deviceId = config.deviceId?.trim();
    if (deviceId != null && deviceId.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.DEVICE_ID.value, deviceId);
    }

    appendInt32Tlv(AirStationConfigFlags.MQTT_ENABLED.value, config.mqttEnabled ? 1 : 0);
    appendUtf8Tlv(AirStationConfigFlags.MQTT_BROKER.value, config.mqttBroker?.trim() ?? '');
    appendInt32Tlv(AirStationConfigFlags.MQTT_PORT.value, config.mqttPort);
    appendInt32Tlv(AirStationConfigFlags.MQTT_USE_TLS.value, config.mqttUseTls ? 1 : 0);
    appendUtf8Tlv(AirStationConfigFlags.MQTT_USERNAME.value, config.mqttUsername?.trim() ?? '');

    final prefix = config.mqttDiscoveryPrefix?.trim();
    if (prefix != null && prefix.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.MQTT_DISCOVERY_PREFIX.value, prefix);
    }
    final mqttName = config.mqttDeviceName?.trim();
    if (mqttName != null && mqttName.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.MQTT_DEVICE_NAME.value, mqttName);
    }
    final cert = config.mqttCertificatePath?.trim();
    if (cert != null && cert.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.MQTT_CERTIFICATE_PATH.value, cert);
    }

    final tz = config.tz?.trim();
    if (tz != null && tz.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.TZ.value, tz);
    }
    final logLevel = config.logLevel?.trim();
    if (logLevel != null && logLevel.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.LOG_LEVEL.value, logLevel);
    }
    final apiKey = config.pendingApiKeyForSecureStore?.trim();
    if (apiKey != null && apiKey.isNotEmpty) {
      appendUtf8Tlv(AirStationConfigFlags.API_KEY.value, apiKey);
    }

    appendInt32Tlv(
      AirStationConfigFlags.SYNC_RTC_FROM_NTP.value,
      config.syncRtcFromNtp ? 1 : 0,
    );
    appendInt32Tlv(
      AirStationConfigFlags.DETECT_MODEL_FROM_SENSORS.value,
      config.detectModelFromSensors ? 1 : 0,
    );
    appendInt32Tlv(
      AirStationConfigFlags.UPLOAD_SD_LOG_TO_DATAHUB.value,
      config.uploadSdLogToDatahub ? 1 : 0,
    );
    appendInt32Tlv(AirStationConfigFlags.CLEAR_SD_CARD.value, config.clearSdCard ? 1 : 0);
    appendInt32Tlv(
      AirStationConfigFlags.REFRESH_SENSORS.value,
      config.refreshSensors ? 1 : 0,
    );

    return out;
  }

  static List<int> mergeTlvRecords(List<int> base, List<int> incoming) {
    final map = <int, Uint8List>{};

    void ingest(List<int> bytes) {
      var i = 0;
      while (i + 2 <= bytes.length) {
        final flag = bytes[i++];
        final len = bytes[i++];
        if (i + len > bytes.length) break;
        map[flag] = Uint8List.fromList(bytes.sublist(i, i + len));
        i += len;
      }
    }

    ingest(base);
    ingest(incoming);

    final out = <int>[];
    for (final entry in map.entries) {
      out
        ..add(entry.key)
        ..add(entry.value.length)
        ..addAll(entry.value);
    }
    return out;
  }

  static int defaultOperationalFlags(LDDeviceModel model) {
    if (model == LDDeviceModel.station) {
      return BleOperationalStatusFlags.configIncomplete;
    }
    return 0;
  }
}
