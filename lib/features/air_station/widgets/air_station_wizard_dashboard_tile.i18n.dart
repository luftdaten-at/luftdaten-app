import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Jetzt konfigurieren",
        "en": "Configure Now",
      } +
      {
        "de": "Konfiguration fortsezten",
        "en": "Continue Configuration",
      } +
      {
        "de": "Warte auf Daten",
        "en": "Waiting for Data",
      } +
      {
        "de": "Daten empfangen",
        "en": "Data Received",
      } +
      {
        "de": "Tippen, um abzuschließen",
        "en": "Tap to complete",
      } +
      {
        "de": "Keine Daten empfangen",
        "en": "No Data Received",
      } +
      {
        "de": "Tippen, um zu beheben",
        "en": "Tap to fix",
      } +
      {
        "de": "Verbindungsfehler",
        "en": "Connection Error",
      };

  String get i18n => localize(this, _t);
}
