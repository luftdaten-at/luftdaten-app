import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_firmware_image.dart';

/// Metadata for a published Badge firmware release on GitHub.
class BadgeFirmwareRelease {
  const BadgeFirmwareRelease({
    required this.tagName,
    required this.version,
    required this.downloadUrl,
    required this.assetName,
  });

  final String tagName;
  final FirmwareVersion version;
  final Uri downloadUrl;
  final String assetName;
}

class BadgeFirmwareReleaseException implements Exception {
  BadgeFirmwareReleaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches latest Badge firmware from GitHub releases.
class BadgeFirmwareReleaseClient {
  BadgeFirmwareReleaseClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const repo = 'luftdaten-at/firmware-badge';
  static const assetName = 'luftdaten-badge.bin';

  final http.Client _http;

  Future<BadgeFirmwareRelease?> fetchLatest() async {
    final uri = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
    final response = await _http.get(
      uri,
      headers: const {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw BadgeFirmwareReleaseException(
        'GitHub releases API returned ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = json['tag_name'] as String? ?? '';
    final version = parseFirmwareVersionFromReleaseTag(tagName);
    if (version == null) {
      throw BadgeFirmwareReleaseException('Unrecognized release tag: $tagName');
    }

    final assets = json['assets'] as List<dynamic>? ?? const [];
    for (final raw in assets) {
      if (raw is! Map<String, dynamic>) continue;
      if (raw['name'] != assetName) continue;
      final url = raw['browser_download_url'] as String?;
      if (url == null || url.isEmpty) continue;
      return BadgeFirmwareRelease(
        tagName: tagName,
        version: version,
        downloadUrl: Uri.parse(url),
        assetName: assetName,
      );
    }

    return null;
  }

  Future<BadgeFirmwareImage> download(BadgeFirmwareRelease release) async {
    final response = await _http.get(release.downloadUrl).timeout(const Duration(minutes: 5));
    if (response.statusCode != 200) {
      throw BadgeFirmwareReleaseException(
        'Firmware download failed (${response.statusCode})',
      );
    }
    return BadgeFirmwareImage(
      bytes: Uint8List.fromList(response.bodyBytes),
      targetVersion: release.version,
    );
  }

  Future<BadgeFirmwareImage?> fetchLatestImage() async {
    final release = await fetchLatest();
    if (release == null) return null;
    return download(release);
  }
}
