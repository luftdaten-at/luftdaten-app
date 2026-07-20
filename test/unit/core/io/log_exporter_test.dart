import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/io/app_file_saver.dart';
import 'package:luftdaten.at/core/io/log_exporter.dart';

void main() {
  group('exportLogFile', () {
    late Directory tempDir;
    var shared = false;
    String? sharedPath;
    String? sharedName;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('log_export_test_');
      shared = false;
      sharedPath = null;
      sharedName = null;
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    AppFileSaver fakeSaver(String? savedPath) => AppFileSaver(
          saveBytesImpl: ({
            required String fileName,
            required Uint8List bytes,
            FileType type = FileType.any,
            List<String>? allowedExtensions,
          }) async =>
              savedPath,
        );

    Future<void> shareCallback(String filePath, String fileName) async {
      shared = true;
      sharedPath = filePath;
      sharedName = fileName;
    }

    test('returns empty when export text is empty', () async {
      final result = await exportLogFile(
        exportText: '',
        tryAndroidSaveDialog: true,
        fileSaver: fakeSaver('/saved/path.txt'),
        shareFile: shareCallback,
        getTempDirectory: () async => tempDir,
        clock: () => DateTime(2026, 3, 20, 14, 30),
      );

      expect(result.outcome, LogExportOutcome.empty);
      expect(shared, isFalse);
    });

    test('returns saved when Android save dialog succeeds', () async {
      final result = await exportLogFile(
        exportText: 'hello log',
        tryAndroidSaveDialog: true,
        fileSaver: fakeSaver('/storage/Download/luftdaten-log-20260320-143000.txt'),
        shareFile: shareCallback,
        getTempDirectory: () async => tempDir,
        clock: () => DateTime(2026, 3, 20, 14, 30),
      );

      expect(result.outcome, LogExportOutcome.saved);
      expect(result.savedPath, '/storage/Download/luftdaten-log-20260320-143000.txt');
      expect(shared, isFalse);
    });

    test('falls back to share when save dialog returns null', () async {
      final result = await exportLogFile(
        exportText: 'hello log',
        tryAndroidSaveDialog: true,
        fileSaver: fakeSaver(null),
        shareFile: shareCallback,
        getTempDirectory: () async => tempDir,
        clock: () => DateTime(2026, 3, 20, 14, 30),
      );

      expect(result.outcome, LogExportOutcome.shared);
      expect(shared, isTrue);
      expect(sharedName, 'luftdaten-log-20260320-143000.txt');
      expect(sharedPath, isNotNull);
      expect(File(sharedPath!).existsSync(), isTrue);
      expect(await File(sharedPath!).readAsString(), 'hello log');
    });

    test('uses share directly when Android save dialog is disabled', () async {
      final result = await exportLogFile(
        exportText: 'ios log',
        tryAndroidSaveDialog: false,
        fileSaver: fakeSaver('/should-not-be-used.txt'),
        shareFile: shareCallback,
        getTempDirectory: () async => tempDir,
        clock: () => DateTime(2026, 3, 20, 14, 30),
      );

      expect(result.outcome, LogExportOutcome.shared);
      expect(shared, isTrue);
    });

    test('returns failed when share throws', () async {
      final result = await exportLogFile(
        exportText: 'broken',
        tryAndroidSaveDialog: false,
        fileSaver: fakeSaver(null),
        shareFile: (_, __) async => throw StateError('share failed'),
        getTempDirectory: () async => tempDir,
        clock: () => DateTime(2026, 3, 20, 14, 30),
      );

      expect(result.outcome, LogExportOutcome.failed);
      expect(result.error, isA<StateError>());
    });
  });
}
