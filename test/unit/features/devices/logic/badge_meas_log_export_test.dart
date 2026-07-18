import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/devices/logic/badge_meas_log_export.dart';

void main() {
  group('BadgeMeasLogStatusFrame', () {
    test('encode and parse round-trip', () {
      final raw = BadgeMeasLogStatusFrame.encode(
        state: BadgeMeasLogState.exporting,
        error: BadgeMeasLogError.none,
        recordCount: 42,
        totalBytes: 1600,
        offset: 512,
      );
      expect(raw, hasLength(14));

      final frame = BadgeMeasLogStatusFrame.parse(raw);
      expect(frame, isNotNull);
      expect(frame!.state, BadgeMeasLogState.exporting);
      expect(frame.error, BadgeMeasLogError.none);
      expect(frame.recordCount, 42);
      expect(frame.totalBytes, 1600);
      expect(frame.offset, 512);
      expect(frame.hasRecords, isTrue);
    });

    test('parse rejects short buffer', () {
      expect(BadgeMeasLogStatusFrame.parse([1, 2, 3]), isNull);
    });
  });

  group('badgeMeasLogErrorMessage', () {
    test('maps known error codes', () {
      expect(badgeMeasLogErrorMessage(BadgeMeasLogError.empty), contains('Kein'));
      expect(badgeMeasLogErrorMessage(BadgeMeasLogError.busyMeasuring), contains('Messmodus'));
    });
  });
}
