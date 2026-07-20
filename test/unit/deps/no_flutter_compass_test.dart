import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec.lock does not depend on flutter_compass', () {
    final lockFile = File('pubspec.lock');
    expect(lockFile.existsSync(), isTrue);

    final contents = lockFile.readAsStringSync();
    expect(contents.contains('flutter_compass:'), isFalse);
    expect(contents.contains('flutter_rotation_sensor:'), isTrue);
  });
}
