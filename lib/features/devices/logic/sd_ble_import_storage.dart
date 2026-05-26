import 'package:get_storage/get_storage.dart';

/// Persists raw JSONL lines imported from wifiless Air Station SD BLE export.
///
/// FIFO cap: [maxBatches] oldest entries are dropped when exceeded.
class SdBleImportStorage {
  SdBleImportStorage() : _box = GetStorage(_boxName);

  static const String _boxName = 'sd_ble_imports';
  static const String _keyBatches = 'batches';
  static const int maxBatches = 30;

  final GetStorage _box;

  static Future<void> ensureInitialized() => GetStorage.init(_boxName);

  /// Most recent last.
  List<SdBleImportBatch> readBatches() {
    final raw = _box.read(_keyBatches);
    if (raw is! List) return [];
    final out = <SdBleImportBatch>[];
    for (final item in raw) {
      if (item is Map) {
        final b = SdBleImportBatch.tryFromJson(Map<String, dynamic>.from(item));
        if (b != null) out.add(b);
      }
    }
    return out;
  }

  Future<void> appendBatch({
    required String bleName,
    required List<String> rawJsonLines,
  }) async {
    final id = '${DateTime.now().toUtc().millisecondsSinceEpoch}_${bleName.hashCode}';
    final batch = SdBleImportBatch(
      importId: id,
      bleName: bleName,
      importedAt: DateTime.now().toUtc(),
      rawJsonLines: List<String>.from(rawJsonLines),
    );
    final list = readBatches().map((e) => e.toJson()).toList();
    list.add(batch.toJson());
    while (list.length > maxBatches) {
      list.removeAt(0);
    }
    await _box.write(_keyBatches, list);
  }
}

class SdBleImportBatch {
  const SdBleImportBatch({
    required this.importId,
    required this.bleName,
    required this.importedAt,
    required this.rawJsonLines,
  });

  final String importId;
  final String bleName;
  final DateTime importedAt;
  final List<String> rawJsonLines;

  Map<String, dynamic> toJson() {
    return {
      'importId': importId,
      'bleName': bleName,
      'importedAtIso': importedAt.toIso8601String(),
      'lineCount': rawJsonLines.length,
      'lines': rawJsonLines,
    };
  }

  static SdBleImportBatch? tryFromJson(Map<String, dynamic> json) {
    try {
      final lines = json['lines'];
      if (lines is! List) return null;
      final raw = lines.map((e) => '$e').toList();
      final iso = json['importedAtIso'] as String?;
      if (iso == null) return null;
      return SdBleImportBatch(
        importId: json['importId'] as String? ?? '',
        bleName: json['bleName'] as String? ?? '',
        importedAt: DateTime.parse(iso).toUtc(),
        rawJsonLines: raw,
      );
    } catch (_) {
      return null;
    }
  }
}
