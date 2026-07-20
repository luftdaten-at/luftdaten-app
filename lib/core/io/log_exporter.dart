import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'app_file_saver.dart';

enum LogExportOutcome { empty, saved, shared, failed }

class LogExportResult {
  const LogExportResult(this.outcome, {this.savedPath, this.error});

  final LogExportOutcome outcome;
  final String? savedPath;
  final Object? error;
}

typedef ShareLogFileCallback = Future<void> Function(String filePath, String fileName);
typedef TempDirectoryGetter = Future<Directory> Function();

/// Writes log text to a temp file, tries Android save dialog, then share sheet.
Future<LogExportResult> exportLogFile({
  required String exportText,
  required bool tryAndroidSaveDialog,
  required AppFileSaver fileSaver,
  required ShareLogFileCallback shareFile,
  TempDirectoryGetter? getTempDirectory,
  DateTime Function()? clock,
}) async {
  if (exportText.isEmpty) {
    return const LogExportResult(LogExportOutcome.empty);
  }

  final now = clock ?? DateTime.now;
  final fileName = 'luftdaten-log-${DateFormat('yyyyMMdd-HHmmss').format(now())}.txt';
  final tempDir = getTempDirectory ?? getTemporaryDirectory;
  final file = File('${(await tempDir()).path}/$fileName');

  try {
    await file.writeAsString(exportText);
    final bytes = Uint8List.fromList(utf8.encode(exportText));

    if (tryAndroidSaveDialog) {
      final savedPath = await fileSaver.saveBytes(
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['txt'],
      );
      if (savedPath != null) {
        return LogExportResult(LogExportOutcome.saved, savedPath: savedPath);
      }
    }

    await shareFile(file.path, fileName);
    return const LogExportResult(LogExportOutcome.shared);
  } catch (error) {
    return LogExportResult(LogExportOutcome.failed, error: error);
  }
}
