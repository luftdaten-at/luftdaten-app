import 'dart:convert';
import 'dart:typed_data';

/// Frame layout for firmware `sd_log_export_characteristic` (see firmware `sd_ble_export.py`
/// and `docs/ble-characteristics.md`).
abstract final class SdBleExportConstants {
  static const int statusIdle = 0;
  static const int statusPartial = 1;
  static const int statusEol = 2;
  static const int statusEof = 3;
  static const int statusErr = 4;

  /// Idle `flags` bit: JSONL file exists and is non-empty.
  static const int flagIdleSdLogNonempty = 0x01;

  /// Error subcodes when `status == statusErr` (see firmware `SUB_*`).
  static const int errNotWifiless = 1;
  static const int errMountFail = 2;
  static const int errOpenFail = 3;
  static const int errReadFail = 4;
  static const int errNoSession = 5;
}

/// Parsed READ value from `sd_log_export_characteristic`.
class SdBleExportFrame {
  SdBleExportFrame({
    required this.status,
    required this.flags,
    required this.payload,
  });

  final int status;
  final int flags;
  final List<int> payload;

  bool get isIdle => status == SdBleExportConstants.statusIdle;

  /// When [isIdle], SD log file exists and has content (firmware sets bit 0).
  bool get idleSdLogNonEmpty =>
      isIdle && (flags & SdBleExportConstants.flagIdleSdLogNonempty) != 0;

  static SdBleExportFrame parse(List<int> raw) {
    if (raw.length < 4) {
      throw FormatException('SD BLE export frame too short: ${raw.length}');
    }
    final bd = ByteData.sublistView(Uint8List.fromList(raw));
    final status = raw[0];
    final flags = raw[1];
    final len = bd.getUint16(2, Endian.big);
    if (raw.length < 4 + len) {
      throw FormatException(
        'SD BLE export frame truncated: need ${4 + len}, have ${raw.length}',
      );
    }
    return SdBleExportFrame(
      status: status,
      flags: flags,
      payload: raw.sublist(4, 4 + len),
    );
  }
}

/// Result of an idle peek on SD export (only meaningful when device returned idle).
class SdBleExportIdleInfo {
  const SdBleExportIdleInfo({required this.sdLogNonEmpty});

  final bool sdLogNonEmpty;
}

/// Result of streaming JSONL via `0x08` START/NEXT.
class SdBleImportResult {
  const SdBleImportResult._({
    required this.ok,
    this.lines = const [],
    this.errorMessage,
    this.errorSubcode,
  });

  const SdBleImportResult.success(this.lines)
      : ok = true,
        errorMessage = null,
        errorSubcode = null;

  factory SdBleImportResult.error(String message, {int? subcode}) {
    return SdBleImportResult._(
      ok: false,
      lines: const [],
      errorMessage: message,
      errorSubcode: subcode,
    );
  }

  final bool ok;
  final List<Map<String, dynamic>> lines;
  final String? errorMessage;
  final int? errorSubcode;

  static String mapErrorSubcode(int subcode) {
    switch (subcode) {
      case SdBleExportConstants.errNotWifiless:
        return 'SD-Export nur im Wifiless-Modus der Air Station verfügbar.';
      case SdBleExportConstants.errMountFail:
        return 'SD-Karte konnte nicht gemountet werden.';
      case SdBleExportConstants.errOpenFail:
        return 'Messprotokoll auf der SD-Karte nicht gefunden oder nicht lesbar.';
      case SdBleExportConstants.errReadFail:
        return 'Lesefehler beim SD-Export.';
      case SdBleExportConstants.errNoSession:
        return 'SD-Export: bitte erneut starten (keine Sitzung).';
      default:
        return 'SD-Export-Fehler (Code $subcode).';
    }
  }
}

/// Decodes one JSONL line from firmware `get_json()` shape.
Map<String, dynamic>? tryDecodeJsonlObject(String line) {
  final t = line.trim();
  if (t.isEmpty) return null;
  try {
    final v = json.decode(t);
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  } catch (_) {
    return null;
  }
}
