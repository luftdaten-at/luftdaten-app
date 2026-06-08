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
      } +
      {
        "de": "Dimension und Farblegende",
        "en": "Dimension and colour legend",
      } +
      {
        "de": "≤ %s µg/m³",
        "en": "≤ %s µg/m³",
      } +
      {
        "de": "> %s – ≤ %s µg/m³",
        "en": "> %s – ≤ %s µg/m³",
      } +
      {
        "de": "> %s µg/m³",
        "en": "> %s µg/m³",
      } +
      {
        "de": "Farben (Eu‑Luftqualitätsindex für Feinstaub, µg/m³ · stündliche Schwellen)",
        "en": "Colours (EU air quality index for particulate matter, µg/m³ · hourly thresholds)",
      } +
      {
        "de": "Orientiert sich an den Farbstufen der Europäischen Umweltagentur.",
        "en": "Bands follow EU EEA colouring for particle maps.",
      } +
      {
        "de": "Farben (Temperatur · Messverlauf)",
        "en": "Colours (temperature · measurement trace)",
      } +
      {
        "de": "< %s °C",
        "en": "< %s °C",
      } +
      {
        "de": "%s °C bis < %s °C",
        "en": "%s °C to < %s °C",
      } +
      {
        "de": "%s °C oder mehr",
        "en": "%s °C or higher",
      } +
      {
        "de": "Farblegende einblenden",
        "en": "Show colour legend",
      } +
      {
        "de": "Farblegende ausblenden",
        "en": "Hide colour legend",
      } +
      {
        "de": "Gut",
        "en": "Good",
      } +
      {
        "de": "Schlecht",
        "en": "Bad",
      } +
      {
        "de": "Letzte 24 Stunden (Stundenmittel)",
        "en": "Last 24 hours (hourly mean)",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}