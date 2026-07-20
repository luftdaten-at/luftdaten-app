import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

typedef SaveBytesCallback = Future<String?> Function({
  required String fileName,
  required Uint8List bytes,
  FileType type,
  List<String>? allowedExtensions,
});

/// Native save-as dialog wrapper (backed by [FilePicker], SPM-capable on iOS).
class AppFileSaver {
  AppFileSaver({SaveBytesCallback? saveBytesImpl})
      : _saveBytes = saveBytesImpl ?? _defaultSaveBytes;

  final SaveBytesCallback _saveBytes;

  Future<String?> saveBytes({
    required String fileName,
    required Uint8List bytes,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) =>
      _saveBytes(
        fileName: fileName,
        bytes: bytes,
        type: type,
        allowedExtensions: allowedExtensions,
      );

  static Future<String?> _defaultSaveBytes({
    required String fileName,
    required Uint8List bytes,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) =>
      FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
        type: type,
        allowedExtensions: allowedExtensions,
      );
}
