import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/shared/utils/string_extensions.dart';

void main() {
  group('StripHtml', () {
    test('strips HTML tags', () {
      expect('<p>hello</p>'.stripHtml, 'hello');
    });

    test('strips HTML entities', () {
      expect('&nbsp;text&amp;'.stripHtml, 'text');
    });

    test('handles mixed tags and entities', () {
      expect('<b>a &amp; b</b>'.stripHtml, 'a   b');
    });

    test('empty string returns empty', () {
      expect(''.stripHtml, '');
    });

    test('plain text unchanged', () {
      expect('no html here'.stripHtml, 'no html here');
    });
  });
}
