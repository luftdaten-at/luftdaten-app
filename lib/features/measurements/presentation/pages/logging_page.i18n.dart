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
      } +
      {
        "de": "Log exportieren",
        "en": "Export log",
      } +
      {
        "de": "Keine Log-Einträge zum Exportieren.",
        "en": "No log entries to export.",
      } +
      {
        "de": "Log konnte nicht exportiert werden.",
        "en": "Could not export log.",
      };

  String get i18n => localize(this, _t);
}