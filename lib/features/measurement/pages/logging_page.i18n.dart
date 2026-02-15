import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {

  static final _t = Translations.byText("de") +
      {
        "de": "Log",
        "en": "Log",
      } +
      {
        "de": "Zum Ende scrollen",
        "en": "Scroll to bottom",
      };

  String get i18n => localize(this, _t);
}