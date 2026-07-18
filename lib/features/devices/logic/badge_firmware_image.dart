import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';

/// Raw ESP-IDF app image plus target firmware version for BLE OTA.
class BadgeFirmwareImage {
  BadgeFirmwareImage({
    required this.bytes,
    required this.targetVersion,
  });

  final Uint8List bytes;
  final FirmwareVersion targetVersion;

  int get size => bytes.length;

  List<int> get sha256Digest => sha256.convert(bytes).bytes;

  /// Whether [targetVersion] is strictly newer than [current] (device rejects equal/older).
  static bool isUpgradeFrom({
    required FirmwareVersion? current,
    required FirmwareVersion target,
  }) {
    if (current == null || current.isUnsetPlaceholder) return true;
    return current.isOlderThan(target);
  }
}

/// Parses GitHub release tags like `v1.2.3` or `1.2.3`.
FirmwareVersion? parseFirmwareVersionFromReleaseTag(String tag) {
  final trimmed = tag.trim();
  if (trimmed.isEmpty) return null;
  final normalized = trimmed.startsWith('v') || trimmed.startsWith('V')
      ? trimmed.substring(1)
      : trimmed;
  final parts = normalized.split('.');
  if (parts.length < 2 || parts.length > 3) return null;
  final major = int.tryParse(parts[0]);
  final minor = int.tryParse(parts[1]);
  final patch = parts.length >= 3 ? int.tryParse(parts[2]) : 0;
  if (major == null || minor == null || patch == null) return null;
  return FirmwareVersion(major, minor, patch);
}

final _filenameVersionPattern = RegExp(
  r'(?:^|[/_-])v?(\d+)\.(\d+)\.(\d+)(?:\.bin$|[/_-])',
  caseSensitive: false,
);

/// Parses semver from filenames like `luftdaten-badge-1.2.3.bin` or `v1.2.3.bin`.
FirmwareVersion? parseFirmwareVersionFromFilename(String pathOrName) {
  final name = pathOrName.split(RegExp(r'[/\\]')).last;
  final match = _filenameVersionPattern.firstMatch(name);
  if (match == null) return null;
  final major = int.tryParse(match.group(1)!);
  final minor = int.tryParse(match.group(2)!);
  final patch = int.tryParse(match.group(3)!);
  if (major == null || minor == null || patch == null) return null;
  return FirmwareVersion(major, minor, patch);
}
