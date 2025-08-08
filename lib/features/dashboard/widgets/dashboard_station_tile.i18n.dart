import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Air Station",
        "en": "Air Station",
      } +
      {
        "de": "Station #%i",
        "en": "Station #%i",
      } +
      {
        "de": "Ladefehler",
        "en": "Error",
      } +
      {
        "de": "Daten konnten nicht geladen werden. Überprüfe deine Internetverbindung.",
        "en": "Could not load data. Check your internet connection.",
      } +
      {
        "de": "Keine Daten",
        "en": "No Data",
      } +
      {
        "de":
            "Von dieser Station sind keine Daten verfügbar. Wenn du die Station zum ersten Mal verwendest, kann es einige Minuten dauern, bis Daten eintreffen.",
        "en":
            "No data from this station was found. If you are using the station for the first time, it may take a few minutes for data to arrive.",
      } +
      {
        "de": "Neu suchen",
        "en": "Try again",
      } +
      {
        "de": "Schließen",
        "en": "Close",
      } +
      {
        "de": "Umbenennen",
        "en": "Rename",
      } +
      {
        "de": "Station umbenennen",
        "en": "Rename Station",
      } +
      {
        "de": "Name",
        "en": "Name",
      } +
      {
        "de": "Aus Favoriten löschen",
        "en": "Remove from Favorites",
      } +
      {
        "de": "Station aus Favoriten entfernen?",
        "en": "Remove station from favorites?",
      } +
      {
        "de": "Details",
        "en": "Details",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
