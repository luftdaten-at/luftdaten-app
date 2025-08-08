import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "%s mit %s %s.",
        "en": "%s running %s %s.",
      } +
      {
        "de": "%s mit Android %s (SDK %s).",
        "en": "%s running Android %s (SDK %s).",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
