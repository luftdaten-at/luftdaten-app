import 'package:luftdaten.at/features/measurements/data/latlng_with_precision.dart';
import 'package:luftdaten.at/features/measurements/data/measured_data.dart';

/// Builds POST bodies for Datahub `POST /api/v1/devices/data/` during workshops.
///
/// Datahub requires paired top-level `workshop` and `location` when tagging a campaign.
class WorkshopDatahubPayload {
  WorkshopDatahubPayload._();

  /// Returns a payload map or `null` when sensor data or phone GPS is missing.
  static Map<String, dynamic>? build({
    required MeasuredDataPoint dataPoint,
    required String deviceChipId,
    required int deviceModelId,
    required String firmware,
    required String workshopId,
    required String apikey,
    required String participant,
  }) {
    final location = dataPoint.location;
    if (location == null) return null;

    final sensors = _sensorsFromMeasuredPoint(dataPoint);
    if (sensors == null || sensors.isEmpty) return null;

    final deviceBlock = <String, dynamic>{
      'time': dataPoint.timestamp.toUtc().toIso8601String(),
      'id': deviceChipId,
      'firmware': firmware,
      'model': deviceModelId,
      'apikey': apikey,
    };

    final workshopBlock = <String, dynamic>{
      'id': workshopId,
      'participant': participant,
      'mode': dataPoint.mode?.name ?? 'walking',
    };

    final locationBlock = _locationBlock(location);

    final j = dataPoint.j;
    if (_isFirmwareStyleMetadata(j)) {
      final merged = Map<String, dynamic>.from(j!);
      merged['device'] = {
        ...Map<String, dynamic>.from(merged['device'] as Map),
        ...deviceBlock,
      };
      merged['sensors'] = sensors;
      merged['workshop'] = workshopBlock;
      merged['location'] = locationBlock;
      merged.remove('station');
      validate(merged);
      return merged;
    }

    final payload = <String, dynamic>{
      'device': deviceBlock,
      'workshop': workshopBlock,
      'location': locationBlock,
      'sensors': sensors,
    };
    validate(payload);
    return payload;
  }

  /// Ensures required workshop + location fields exist (Datahub contract).
  static void validate(Map<String, dynamic> payload) {
    final workshop = payload['workshop'];
    if (workshop is! Map) {
      throw ArgumentError('Workshop payload missing workshop block');
    }
    final workshopId = workshop['id']?.toString();
    if (workshopId == null || workshopId.isEmpty) {
      throw ArgumentError('Workshop payload missing workshop.id');
    }

    final location = payload['location'];
    if (location is! Map) {
      throw ArgumentError(
        'Workshop payload missing location block (required when workshop is present)',
      );
    }
    final lat = location['lat'];
    final lon = location['lon'];
    if (lat is! num || lon is! num) {
      throw ArgumentError('Workshop payload location must include numeric lat and lon');
    }

    final device = payload['device'];
    if (device is! Map) {
      throw ArgumentError('Workshop payload missing device block');
    }
    final sensors = payload['sensors'];
    if (sensors is! Map || sensors.isEmpty) {
      throw ArgumentError('Workshop payload missing sensors');
    }
  }

  static bool _isFirmwareStyleMetadata(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) return false;
    final device = j['device'];
    final sensors = j['sensors'];
    return device is Map && sensors is Map && sensors.isNotEmpty;
  }

  static Map<String, dynamic> _locationBlock(LatLngWithPrecision location) {
    return {
      'lat': location.latitude,
      'lon': location.longitude,
    };
  }

  static Map<String, dynamic>? _sensorsFromMeasuredPoint(MeasuredDataPoint dataPoint) {
    if (dataPoint.sensorData.isEmpty) return null;

    final sensors = <String, dynamic>{};
    for (var i = 0; i < dataPoint.sensorData.length; i++) {
      final sp = dataPoint.sensorData[i];
      if (sp.sensor == LDSensor.unknown) continue;

      final data = <String, dynamic>{};
      for (final entry in sp.values.entries) {
        if (entry.key != MeasurableQuantity.unknown) {
          final v = entry.value;
          data['${entry.key.id}'] = (v.isNaN || v.isInfinite) ? null : v;
        }
      }
      if (data.isNotEmpty) {
        sensors['${i + 1}'] = {
          'type': sp.sensor.id,
          'data': data,
        };
      }
    }
    if (sensors.isEmpty) return null;
    return sensors;
  }
}
