import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/io/app_file_saver.dart';

void main() {
  group('AppFileSaver', () {
    test('forwards fileName, bytes, type, and allowedExtensions', () async {
      String? capturedFileName;
      Uint8List? capturedBytes;
      FileType? capturedType;
      List<String>? capturedExtensions;

      final saver = AppFileSaver(
        saveBytesImpl: ({
          required String fileName,
          required Uint8List bytes,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
        }) async {
          capturedFileName = fileName;
          capturedBytes = bytes;
          capturedType = type;
          capturedExtensions = allowedExtensions;
          return '/storage/emulated/0/Download/$fileName';
        },
      );

      final bytes = Uint8List.fromList([1, 2, 3]);
      final path = await saver.saveBytes(
        fileName: 'annotated.png',
        bytes: bytes,
        type: FileType.image,
        allowedExtensions: const ['png'],
      );

      expect(path, '/storage/emulated/0/Download/annotated.png');
      expect(capturedFileName, 'annotated.png');
      expect(capturedBytes, bytes);
      expect(capturedType, FileType.image);
      expect(capturedExtensions, const ['png']);
    });

    test('returns null when save callback returns null', () async {
      final saver = AppFileSaver(
        saveBytesImpl: ({
          required String fileName,
          required Uint8List bytes,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
        }) async =>
            null,
      );

      final path = await saver.saveBytes(
        fileName: 'test.txt',
        bytes: Uint8List.fromList([65]),
      );

      expect(path, isNull);
    });
  });
}
