import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Aus Favoriten entfernen",
        "en": "Remove from favorites",
      } +
      {
        "de": "Zu Favoriten hinzufügen",
        "en": "Add to favorites",
      } +
      {
        "de": "Standort konnte nicht ermittelt werden",
        "en": "Could not determine location",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
