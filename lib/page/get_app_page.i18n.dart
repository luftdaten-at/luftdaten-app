import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {

  static final _t = Translations.byText("de") +
      {
        "de": "Luftdaten.at App",
        "en": "Luftdaten.at App",
      } +
      {
        "de": "Link kopiert",
        "en": "Copied to clipboard",
      };

  String get i18n => localize(this, _t);
}