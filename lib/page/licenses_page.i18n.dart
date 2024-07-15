import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Package-Lizenzen",
        "en": "Package Licenses",
      };

  String get i18n => localize(this, _t);
}
