import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {

  static final _t = Translations.byText("de") +
      {
        "de": 'Station #%s',
        "en": 'Station #%s',
      } +
      {
        "de": "Aus Favoriten entfernen",
        "en": "Remove from favorites",
      } +
      {
        "de": "Zu Favoriten hinzufügen",
        "en": "Add to favorites",
      } +
      {
        "de": "Lade Daten von Server",
        "en": "Loading...",
      } +
      {
        "de": "Keine Daten verfügbar",
        "en": "No data available",
      } +
      {
        "de": "Feinstaubbelastung (μg/m³)",
        "en": "Particulate matter (μg/m³)",
      } +
      {
        "de": "Details",
        "en": "Details",
      } +
      {
        "de": "Schließen",
        "en": "Close",
      } +
      {
        "de": "Messdaten",
        "en": "Manage data",
      } +
      {
        "de": "Speichern",
        "en": "Save",
      } +
      {
        "de": "Vergrößern",
        "en": "Zoom in",
      } +
      {
        "de": "Verkleinern",
        "en": "Zoom out",
      } +
      {
        "de": "Messung starten, um Notizen zu einem Messwert hizuzufügen.",
        "en": "Start a measurement first.",
      } +
      {
        "de": "Keine Messungen vorhanden",
        "en": "No measurements available",
      } +
      {
        "de": "Notiz hinzufügen",
        "en": "Add note",
      } +
      {
        "de": "Foto hinzufügen",
        "en": "Add photo",
      } +
      {
        "de": "Um Fotos aufzunehmen, ist die Kamera-Berechtigung benötigt.",
        "en": "The camera permission is required for taking photos.",
      } +
      {
        "de": "Kamera-Berechtigung",
        "en": "Camera Permission",
      } +
      {
        "de": "Abbrechen",
        "en": "Cancel",
      } +
      {
        "de": "Anfragen",
        "en": "Request",
      } +
      {
        "de": "Auf Standort zentrieren",
        "en": "Center on location",
      } +
      {
        "de": "Angezeigte Feinstaubgröße auswählen",
        "en": "Select PM size to display",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}