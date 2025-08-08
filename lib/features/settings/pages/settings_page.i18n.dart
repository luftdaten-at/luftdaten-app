import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Einstellungen",
        "en": "Settings",
      } +
      {
        "de": "Generell",
        "en": "General",
      } +
      {
        "de": "Wakelock",
        "en": "Wakelock",
      } +
      {
        "de": "Bildschirm während Messung nicht ausschalten.",
        "en": "Keep screen alive during measurements.",
      } +
      {
        "de": "Sprache",
        "en": "Language",
      } +
      {
        "de": "Karte",
        "en": "Map",
      } +
      {
        "de": "Karte anzeigen",
        "en": "Show map page",
      } +
      {
        "de": "Karte kann deaktiviert werden, um mobilen Datenverbrauch zu reduzieren.",
        "en": "Map can be deactivated to reduce mobile data usage.",
      } +
      {
        "de": "Stationäre Messstationen anzeigen",
        "en": "Show stationary monitoring stations",
      } +
      {
        "de": "Daten der sensor.community auf der Karte anzeigen.",
        "en": "Show sensor.community data on the map.",
      } +
      {
        "de": "Zoom-Icons",
        "en": "Zoom icons",
      } +
      {
        "de": "Zoom-Icons auf der Karte anzeigen.",
        "en": "Show zoom icons on the map.",
      } +
      {
        "de": "Kamera-Icon",
        "en": "Camera icon",
      } +
      {
        "de": "Kamera-Icon auf der Karte anzeigen.",
        "en": "Show camera icon on the map.",
      } +
      {
        "de": "Notiz-Icon",
        "en": "Quick notes icon",
      } +
      {
        "de": "Notiz-Icon auf der Karte anzeigen.",
        "en": "Show quick note icon on the map.",
      } +
      {
        "de": "Karte autozentrieren",
        "en": "Follow location on map",
      } +
      {
        "de": "Luftkarte während Messung automatisch auf deinen Standort zentrieren.",
        "en": "Center map on your location while measuring.",
      } +
      {
        "de": "Messgeräte",
        "en": "Devices",
      } +
      {
        "de": "Automatisch verbinden",
        "en": "Autoconnect",
      } +
      {
        "de": "Automatische Verbindung für neue Messgeräte standardmäßig einschalten.",
        "en": "Turn on autoconnect for new devices by default.",
      } +
      {
        "de": "Alle Geräte löschen",
        "en": "Delete all Devices",
      } +
      {
        "de": "Alle gescannten Messgeräte aus der App entfernen?",
        "en": "Delete all configured devices from the app?",
      } +
      {
        "de": "Alle Geräte löschen",
        "en": "Delete all devices",
      } +
      {
        "de": "Abbrechen",
        "en": "Cancel",
      } +
      {
        "de": "Löschen",
        "en": "Delete all",
      } +
      {
        "de": "Über App",
        "en": "About",
      } +
      {
        "de": "App-Version",
        "en": "App version",
      } +
      {
        "de": "für",
        "en": "for",
      } +
      {
        "de": "Datenschutzerklärung",
        "en": "Privacy policy",
      } +
      {
        "de": "OpenStreetMap-Lizenz",
        "en": "OpenStreetMap licence",
      } +
      {
        "de": "Wir verwenden OpenStreetMap für die Luftkarte.",
        "en": "We use OpenStreetMap for the map view.",
      } +
      {
        "de": "Kontakt",
        "en": "Contact Luftdaten.at",
      } +
      {
        "de": "App Download-Link anzeigen",
        "en": "Show app download link",
      } +
      {
        "de": "Entwickleroptionen",
        "en": "Developer Options",
      } +
      {
        "de": "Systemversion",
        "en": "System version",
      } +
      {
        "de": "Berechtigungen prüfen",
        "en": "Check permissions",
      } +
      {
        "de": "Berechtigungsstatus",
        "en": "Permission Status",
      } +
      {
        "de": "Standort",
        "en": "Location",
      } +
      {
        "de": "Bluetooth/Geräte in der Nähe",
        "en": "Bluetooth/Nearby Devices",
      } +
      {
        "de": "Log-Konsole",
        "en": "Log console",
      } +
      {
        "de": "Serielle BLE-Konsole",
        "en": "Serial BLE console",
      } +
      {
        "de": "Willkommensbildschirm öffnen",
        "en": "Show welcome screen",
      } +
      {
        "de": "Daten exportieren",
        "en": "Export data",
      } +
      {
        "de": "Messdaten, Geräte- und Appeinstellungen exportieren.",
        "en": "Export all measurement, device and settings data.",
      } +
      {
        "de": "Immer erlaubt",
        "en": "Always allowed",
      } +
      {
        "de": "Erlaubt",
        "en": "Allowed",
      } +
      {
        "de": "Erlaubt, während App geöffnet ist",
        "en": "Allowed while in use",
      } +
      {
        "de": "Nicht erlaubt",
        "en": "Denied",
      } +
      {
        "de": "Messungs-Einstellungen",
        "en": "Measurement preferences",
      } +
      {
        "de": "Nur folgende Werte messen:",
        "en": "Only measure the following values:",
      } +
      {
        "de": "(Sofern von Messgerät untersützt)",
        "en": "(Where supported by device)",
      } +
      {
        "de": "PM1.0 (μg/m³)",
        "en": "PM1.0 (μg/m³)",
      } +
      {
        "de": "Feinstaub mit Durchmesser unter 1,0 μm.",
        "en": "Particulate matter with diameter below 1.0 μm.",
      } +
      {
        "de": "PM2.5 (μg/m³)",
        "en": "PM2.5 (μg/m³)",
      } +
      {
        "de": "Feinstaub mit Durchmesser unter 2,5 μm.",
        "en": "Particulate matter with diameter below 2.5 μm.",
      } +
      {
        "de": "PM4.0 (μg/m³)",
        "en": "PM4.0 (μg/m³)",
      } +
      {
        "de": "Feinstaub mit Durchmesser unter 4,0 μm.",
        "en": "Particulate matter with diameter below 4.0 μm.",
      } +
      {
        "de": "PM10.0 (μg/m³)",
        "en": "PM10.0 (μg/m³)",
      } +
      {
        "de": "Feinstaub mit Durchmesser unter 10,0 μm.",
        "en": "Particulate matter with diameter below 10.0 μm.",
      } +
      {
        "de": "Temperatur (°C)",
        "en": "Temperature (°C)",
      } +
      {
        "de": "Relative Luftfeuchtigkeit (%)",
        "en": "Relative humidity (%)",
      } +
      {
        "de": "VOC (Index)",
        "en": "VOC (Index)",
      } +
      {
        "de": "Flüchtige organische Verbindungen.",
        "en": "Volatile organic compounds.",
      } +
      {
        "de":
            "Der VOC-Index beschreibt die aktuelle VOC-Belastung relativ zum Mittelwert der letzten 24 Stunden in Prozent.",
        "en":
            "The VOC index describes the current VOC load relative to the average of the last 24 hours, in percent.",
      } +
      {
        "de": "VOC-Index",
        "en": "VOC Index",
      } +
      {
        "de": "Schließen",
        "en": "Close",
      } +
      {
        "de": "Mehr Details",
        "en": "More details",
      } +
      {
        "de": "NOX (Index)",
        "en": "NOX (Index)",
      } +
      {
        "de": "Stickoxide.",
        "en": "Nitrogen oxides.",
      } +
      {
        "de":
            "Der NOX-Index beschreibt die aktuelle NOX-Belastung relativ zum Mittelwert der letzten 24 Stunden in Prozent.",
        "en":
            "The NOX index describes the current NOX load relative to the average of the last 24 hours, in percent.",
      } +
      {
        "de": "NOX-Index",
        "en": "NOX Index",
      } +
      {
        "de": "Luftdruck (hPa)",
        "en": "Air pressure (hPa)",
      } +
      {
        "de": "Benachrichtigungen",
        "en": "Notifications",
      } +
      {
        "de": "WHO-Grenzwerte-Benachrichtigung",
        "en": "WHO threshold notifications",
      } +
      {
        "de": "Bei Überschreiten der WHO-Grenzwerte für Feinstaub benachrichtigen.",
        "en": "Notify when measured values exceed WHO thresholds for particulate matter.",
      } +
      {
        "de": "Vibrieren",
        "en": "Vibrate",
      } +
      {
        "de": "Bei Überschreiten der WHO-Grenzwerte für Feinstaub vibrieren.",
        "en": "Vibrate when measured values exceed WHO thresholds for particulate matter.",
      } +
      {
        "de": "Standort aufzeichnen",
        "en": "Record location",
      } +
      {
        "de": "Ortungsdaten zu Messpunkten hinzufügen.",
        "en": "Add location data to measurements.",
      } +
      {
        "de": "Mit mehreren Geräten messen",
        "en": "Measure with multiple devices",
      } +
      {
        "de": "Auswahl mehrerer Geräte für gleichzeitige Messungen erlauben.",
        "en": "Allow selection of multiple devices for simultaneous measurements.",
      } +
      {
        "de": "Dashboard",
        "en": "Dashboard",
      } +
      {
        "de": "Reiter Air-Station-Geräte",
        "en": "Air Station tab",
      } +
      {
        "de": "Reiter Favoriten",
        "en": "Favorites tab",
      } +
      {
        "de": "Reiter tragbare Messgeräte",
        "en": "Portable devices tab",
      } +
      {
        "de": "Package-Lizenzen",
        "en": "Package licenses",
      } +
      {
        "de": "BLE-Geräte in der Nähe",
        "en": "BLE Device Scanner",
      } +
      {
        "de": "Nach Luftdaten.at-Geräten in der Nähe suchen.",
        "en": "Search for nearby Luftdaten.at devices.",
      } +
      {
        "de": "Staging-Server verwenden",
        "en": "Use staging server",
      };

  String get i18n => localize(this, _t);
}
