import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Messungen verwalten",
        "en": "Manage Measurements",
      } +
      {
        "de": "Aktuelle Auswahl:",
        "en": "Current selection:",
      } +
      {
        "de": "Keine Messungen ausgewählt.",
        "en": "No measurements selected.",
      } +
      {
        "de": "Frühere Messungen:",
        "en": "Earlier measurements:",
      } +
      {
        "de": "Aktionen:",
        "en": "Actions:",
      } +
      {
        "de": "Auswahl anzeigen",
        "en": "Show selection",
      } +
      {
        "de": "Auswahl exportieren",
        "en": "Export selection",
      } +
      {
        "de": "Schließen",
        "en": "Close",
      } +
      {
        "de": "Importierte Messung",
        "en": "Imported measurement",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
