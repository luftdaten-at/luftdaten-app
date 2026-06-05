import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Verbinde mit Gerät…",
        "en": "Connecting to device…",
      } +
      {
        "de": "Sensoren werden geladen…",
        "en": "Loading sensors…",
      } +
      {
        "de": "Keine Sensorinformationen verfügbar",
        "en": "No sensor information available",
      } +
      {
        "de": "Sensoren",
        "en": "Sensors",
      } +
      {
        "de": "Geräteinfo",
        "en": "Device info",
      } +
      {
        "de": "Geräteinfo wird geladen…",
        "en": "Loading device info…",
      } +
      {
        "de": "Geräteinfo ist nach der Verbindung verfügbar",
        "en": "Device info is available after connecting",
      } +
      {
        "de": "Firmware-Version: ",
        "en": "Firmware version: ",
      } +
      {
        "de": "Misst: %s",
        "en": "Measures: %s",
      } +
      {
        "de": "Seriennummer: %s",
        "en": "Serial number: %s",
      } +
      {
        "de": "Sensor-Firmware: %s",
        "en": "Sensor firmware: %s",
      } +
      {
        "de": "Hardware-Version: %s",
        "en": "Hardware version: %s",
      } +
      {
        "de": "Protokoll-Version: %s",
        "en": "Protocol version: %s",
      } +
      {
        "de": "Sensirion Sen5x",
        "en": "Sensirion Sen5x",
      } +
      {
        "de": "Bosch Sensortec BME680",
        "en": "Bosch Sensortec BME680",
      } +
      {
        "de": "Bosch Sensortec BMP280",
        "en": "Bosch Sensortec BMP280",
      } +
      {
        "de": "Sensirion Scd4x",
        "en": "Sensirion Scd4x",
      } +
      {
        "de": "Umbenennen",
        "en": "Rename",
      } +
      {
        "de": "Name: ",
        "en": "Name: ",
      } +
      {
        "de": "Adresse: ",
        "en": "Address: ",
      } +
      {
        "de": "Status: ",
        "en": "Status: ",
      } +
      {
        "de": "Geräte-Info",
        "en": "Device info",
      } +
      {
        "de": "Gerät konfigurieren",
        "en": "Configure device",
      } +
      {
        "de": "Gerät entfernen",
        "en": "Remove device",
      } +
      {
        "de": "Gerät: ",
        "en": "Device: ",
      } +
      {
        "de": "Sensor-ID: ",
        "en": "Sensor ID: ",
      } +
      {
        "de": "Sensor-ID kopiert!",
        "en": "Sensor ID copied!",
      } +
      {
        "de": 'Die Sensor-ID wird benötigt, um die Station in der '
            'Sensor.Community einzutragen. Anweisungen hierzu findest '
            'du auf unserer Webseite.',
        "en": 'The sensor ID is required to register the station in the '
            'Sensor.Community. Instructions can be found on our website.',
      } +
      {
        "de": "Startup (BLE) …",
        "en": "Startup (BLE) …",
      } +
      {
        "de": "SD-Import (BLE)",
        "en": "SD import (BLE)",
      } +
      {
        "de": "Gerät",
        "en": "Device",
      } +
      {
        "de": "aus der Geräteliste entfernen?",
        "en": "from the device list?",
      } +
      {
        "de": "Gerät löschen?",
        "en": "Delete device?",
      } +
      {
        "de": "Behalten",
        "en": "Keep",
      } +
      {
        "de": "Löschen",
        "en": "Delete",
      } +
      {
        "de": "Sensoren:",
        "en": "Sensors:",
      } +
      {
        "de": "Baue Verbindung auf...",
        "en": "Connecting...",
      } +
      {
        "de": "Verbunden",
        "en": "Connected",
      } +
      {
        "de": "Keine Verbindung",
        "en": "Not connected",
      } +
      {
        "de": "Sichtbar",
        "en": "Visible",
      } +
      {
        "de": "Nicht in der Nähe",
        "en": "Not in range",
      } +
      {
        "de": "Fehler",
        "en": "Error",
      } +
      {
        "de": "Konfiguration",
        "en": "Configuration",
      } +
      {
        "de": "Konfiguration wird geladen…",
        "en": "Loading configuration…",
      } +
      {
        "de": "Keine gespeicherte Konfiguration",
        "en": "No saved configuration",
      } +
      {
        "de": "Zuletzt konfiguriert: ",
        "en": "Last configured: ",
      } +
      {
        "de": "Device-ID: ",
        "en": "Device ID: ",
      } +
      {
        "de": "Messintervall: ",
        "en": "Measurement interval: ",
      } +
      {
        "de": "Auto-Update: ",
        "en": "Auto-update: ",
      } +
      {
        "de": "Standort: ",
        "en": "Location: ",
      } +
      {
        "de": "Zeitzone: ",
        "en": "Timezone: ",
      } +
      {
        "de": "MQTT: ",
        "en": "MQTT: ",
      } +
      {
        "de": "Aktiv",
        "en": "Active",
      } +
      {
        "de": "Aus",
        "en": "Off",
      } +
      {
        "de": "Anzeigename: ",
        "en": "Display name: ",
      } +
      {
        "de": "Messintervall (App): ",
        "en": "Measurement interval (app): ",
      } +
      {
        "de": "Automatisch verbinden: ",
        "en": "Auto-connect: ",
      } +
      {
        "de": "Ja",
        "en": "Yes",
      } +
      {
        "de": "Nein",
        "en": "No",
      } +
      {
        "de": "Konfiguration aktuell",
        "en": "Configuration up to date",
      } +
      {
        "de": "Konfiguration abweichend",
        "en": "Configuration differs",
      } +
      {
        "de": "Keine lokale Konfiguration",
        "en": "No local configuration",
      } +
      {
        "de": "BLE-Konfiguration nicht lesbar",
        "en": "BLE configuration not readable",
      } +
      {
        "de": "Nur App-Einstellung",
        "en": "App setting only",
      } +
      {
        "de": "WLAN: ",
        "en": "Wi-Fi: ",
      } +
      {
        "de": "Nicht konfiguriert",
        "en": "Not configured",
      } +
      {
        "de": "WLAN SSID: ",
        "en": "Wi-Fi SSID: ",
      } +
      {
        "de": "WLAN Passwort: ",
        "en": "Wi-Fi password: ",
      } +
      {
        "de": "Gespeichert",
        "en": "Stored",
      } +
      {
        "de": "Nicht gespeichert",
        "en": "Not stored",
      } +
      {
        "de": "WLAN auf Gerät: ",
        "en": "Wi-Fi on device: ",
      } +
      {
        "de": "SSID konfiguriert",
        "en": "SSID configured",
      } +
      {
        "de": "SSID nicht konfiguriert",
        "en": "SSID not configured",
      } +
      {
        "de": "WLAN-Gerätestatus nach Verbindung verfügbar",
        "en": "Wi-Fi device status available after connecting",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
