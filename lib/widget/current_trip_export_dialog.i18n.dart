import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Messungen exportieren",
        "en": "Export Measurements",
      } +
      {
        "de": "Messungen:",
        "en": "Measurements:",
      } +
      {
        "de": "Dateiformat:",
        "en": "File format:",
      } +
      {
        "de": "Abbrechen",
        "en": "Cancel",
      } +
      {
        "de": "Teilen",
        "en": "Share",
      } +
      {
        "de": "CSV",
        "en": "CSV",
      } +
      {
        "de": "Luftdaten.at JSON (empfohlen)",
        "en": "Luftdaten.at JSON (recommended)",
      } +
      {
        "de": "Zum Export in andere Software.",
        "en": "For use in other software.",
      } +
      {
        "de": "Zur Verwendung innerhalb von Luftdaten.at-Produkten.",
        "en": "For use within Luftdaten.at products.",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}