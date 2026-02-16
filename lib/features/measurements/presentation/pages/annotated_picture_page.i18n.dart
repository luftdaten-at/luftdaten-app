import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {

  static final _t = Translations.byText("de") +
      {
        "de": "Luftqualität dokumentieren",
        "en": "Document Air Quality",
      } +
      {
        "de": "Kamera wird geladen...",
        "en": "Loading camera...",
      } +
      {
        "de": "Kamera konnte nicht geöffnet werden",
        "en": "Failed to open camera",
      } +
      {
        "de": "Messdaten-Box schattieren",
        "en": "Shade measurement data box",
      } +
      {
        "de": "Foto aufnehmen",
        "en": "Take photo",
      } +
      {
        "de": "Foto teilen",
        "en": "Share",
      } +
      {
        "de": "Foto speichern",
        "en": "Save",
      } +
      {
        "de": "Neues Foto",
        "en": "New photo",
      } +
      {
        "de": "Beta-Version",
        "en": "Beta Version",
      } +
      {
        "de": "Die Kamera-Funktion ist noch in Entwicklung.",
        "en": "The camera function is still in development.",
      };

  String get i18n => localize(this, _t);
}