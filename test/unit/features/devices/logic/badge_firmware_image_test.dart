import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/logic/badge_firmware_image.dart';
import 'package:luftdaten.at/features/devices/logic/ble_ota.dart';

void main() {
  group('BadgeFirmwareImage', () {
    test('parseFirmwareVersionFromReleaseTag accepts v-prefix and plain tags', () {
      final v1 = parseFirmwareVersionFromReleaseTag('v1.2.3');
      expect(v1?.major, 1);
      expect(v1?.minor, 2);
      expect(v1?.patch, 3);
      final v2 = parseFirmwareVersionFromReleaseTag('2.0.1');
      expect(v2?.major, 2);
      expect(parseFirmwareVersionFromReleaseTag('bad'), isNull);
    });

    test('parseFirmwareVersionFromFilename reads semver from common names', () {
      final v1 = parseFirmwareVersionFromFilename('luftdaten-badge-1.2.3.bin');
      expect(v1?.major, 1);
      expect(v1?.minor, 2);
      expect(v1?.patch, 3);
      final v2 = parseFirmwareVersionFromFilename('/tmp/v2.0.0.bin');
      expect(v2?.major, 2);
      expect(parseFirmwareVersionFromFilename('luftdaten-badge.bin'), isNull);
    });

    test('isUpgradeFrom requires strictly newer target', () {
      expect(
        BadgeFirmwareImage.isUpgradeFrom(
          current: const FirmwareVersion(1, 0, 0),
          target: const FirmwareVersion(1, 0, 1),
        ),
        isTrue,
      );
      expect(
        BadgeFirmwareImage.isUpgradeFrom(
          current: const FirmwareVersion(1, 0, 0),
          target: const FirmwareVersion(1, 0, 0),
        ),
        isFalse,
      );
    });
  });

  group('BleOta payloads', () {
    test('buildBleOtaStartPayload encodes size sha and version', () {
      final image = BadgeFirmwareImage(
        bytes: Uint8List.fromList(List<int>.filled(8, 0xAB)),
        targetVersion: const FirmwareVersion(1, 2, 3),
      );
      final payload = buildBleOtaStartPayload(image: image);
      expect(payload, hasLength(40));
      expect(payload.first, BleOtaCommand.start);
      expect(payload.sublist(1, 5), [0, 0, 0, 8]);
      expect(payload.sublist(37, 40), [1, 2, 3]);
      expect(payload.sublist(5, 37), image.sha256Digest);
    });

    test('BleOtaStatusFrame roundtrip', () {
      const frame = BleOtaStatusFrame(
        state: BleOtaState.receiving,
        error: BleOtaError.none,
        progressPct: 42,
        bytesReceived: 1234,
      );
      final encoded = BleOtaStatusFrame.encode(
        state: frame.state,
        error: frame.error,
        progressPct: frame.progressPct,
        bytesReceived: frame.bytesReceived,
      );
      final parsed = BleOtaStatusFrame.parse(encoded);
      expect(parsed?.state, frame.state);
      expect(parsed?.progressPct, frame.progressPct);
      expect(parsed?.bytesReceived, frame.bytesReceived);
    });

    test('bleOtaChunkSizeForMtu subtracts ATT overhead', () {
      expect(bleOtaChunkSizeForMtu(517), 514);
      expect(bleOtaChunkSizeForMtu(23), 20);
    });
  });
}
