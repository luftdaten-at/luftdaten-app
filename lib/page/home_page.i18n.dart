import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Dashboard",
        "en": "Dashboard",
      } +
      {
        "de": "Luftkarte",
        "en": "Map",
      } +
      {
        "de": "Messwerte",
        "en": "Data",
      } +
      {
        "de": "Geräte",
        "en": "Devices",
      } +
      {
        "de": "Einstellungen",
        "en": "Settings",
      } +
      {
        "de": "Log",
        "en": "Log",
      } +
      {
        "de": "Serielle BLE-Konsole",
        "en": "Serial BLE console",
      } +
      {
        "de":
            "Soll die Anwendung beendet werden? Sollten noch Messungen laufen werden diese gestoppt",
        "en":
            "Do you want to terminate the application? If measurements are still running, they will be stopped",
      } +
      {
        "de": "Anwendung schließen",
        "en": "Close application",
      } +
      {
        "de": "Route auswählen",
        "en": "Select route",
      } +
      {
        "de": "Gespeicherte Messungen",
        "en": "Past measurements",
      } +
      {
        "de": "Daten importieren",
        "en": "Import data",
      } +
      {
        "de": "Daten exportieren",
        "en": "Export data",
      } +
      {
        "de": "Messdaten verwalten",
        "en": "Manage data",
      } +
      {
        "de": "Favoriten",
        "en": "Favorites",
      } +
      {
        "de":
            "Neu geladene Messpunkte zur aktuellen Anzeige hinzufügen oder aktuelle Anzeige überschreiben?",
        "en":
            "Add newly loaded measurement points to the current display or overwrite current display?",
      } +
      {
        "de": "Daten hinzufügen",
        "en": "Add or Overwrite",
      } +
      {
        "de": "Hinzufügen",
        "en": "Add",
      } +
      {
        "de": "Überschreiben",
        "en": "Overwrite",
      } +
      {
        "de": "Ein Fehler ist aufgetreten.",
        "en": "An error occurred.",
      } +
      {
        "de": "Importfehler",
        "en": "Import Failed",
      } +
      {
        "de": "Workshop läuft",
        "en": "Workshop is running",
      } +
      {
        "de": 'Du sendest Messwerte als Teil des Workshops „%s“. '
            'Dieser Workshop läuft noch bis %s, %s Uhr.',
        "en": 'You are sending measurements as part of the workshop "%s". '
            'This workshop will continue until %s, %s.',
      } +
      {
        "de": "Austreten",
        "en": "Leave",
      } +
      {
        "de": "Workshop verlassen",
        "en": "Leave Workshop",
      } +
      {
        "de": "Aus dem aktuellen Workshop austreten?",
        "en": "Leave the current workshop?",
      } +
      {
        "de": "dd.MM.yyyy",
        "en": "MMM dd, yyyy",
      } +
      {
        "de": "HH:mm",
        "en": "hh:mm a",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
