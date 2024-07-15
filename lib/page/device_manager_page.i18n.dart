import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Die Luftdaten.at App braucht Zugriff auf ihre Kamera",
        "en": "The Luftdaten.at app needs access to your camera",
      } +
      {
        "de": "Kamera-Berechtigung",
        "en": "Camera Permission",
      } +
      {
        "de": "Dieses Gerät unterstützt Bluetooth nicht",
        "en": "This device does not support Bluetooth",
      } +
      {
        "de": "Die Luftdaten.at App braucht Zugriff auf Bluetooth und den Standort",
        "en": "The Luftdaten.at app needs access to Bluetooth and location",
      } +
      {
        "de": "Bluetooth ist ausgeschalten. Um diese App zu nutzen muss es eingeschalten werden",
        "en": "Bluetooth is turned off. To connect to BLE devices, it must be turned on",
      } +
      {
        "de": "Die Standort-Erkennung (GPS) muss eingeschaltet werden",
        "en": "Location must be turned on",
      } +
      {
        "de":
            'Du hast noch kein Gerät aktiviert. Verwende die Funktion "Gerät hinzufügen" und scanne den QR Code deines Geräts',
        "en": 'Tap the "Add Device" button and scan the QR code of your device',
      } +
      {
        "de": "Neues Gerät hinzufügen",
        "en": "Add Device",
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
        "de": "Gerät registrieren",
        "en": "Register device",
      } +
      {
        "de": "Gerät konfigurieren",
        "en": "Configure device",
      } +
      {
        "de": "Gerät",
        "en": "Delete device",
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
        "de": "Löschen",
        "en": "Delete",
      } +
      {
        "de": "Behalten",
        "en": "Keep",
      } +
      {
        "de": "Gerät entfernen",
        "en": "Remove device",
      } +
      {
        "de": "Verbinden",
        "en": "Connect",
      } +
      {
        "de": "Wird verbunden...",
        "en": "Connecting...",
      } +
      {
        "de": "Trennen",
        "en": "Disconnect",
      } +
      {
        "de": "QR-Code Scannen",
        "en": "Scan QR Code",
      } +
      {
        "de": "QR-Code ungültig",
        "en": "Invalid QR Code",
      } +
      {
        "de": "Brauche Zugriffsrechte für Kamera",
        "en": "Need access to camera",
      } +
      {
        "de": "Anfordern",
        "en": "Request",
      } +
      {
        "de": "Daten manuell eingeben",
        "en": "Enter data manually",
      } +
      {
        "de": "Modell",
        "en": "Model",
      } +
      {
        "de": "Daten",
        "en": "Details",
      } +
      {
        "de": "Gerätename",
        "en": "Device name",
      } +
      {
        "de": "Kennnummer",
        "en": "Device ID",
      } +
      {
        "de": "Überprüfe deine Eingaben.",
        "en": "Check your inputs.",
      } +
      {
        "de": "Daten ungültig",
        "en": "Invalid data",
      } +
      {
        "de": "Messdaten abfragen alle",
        "en": "Query measurement data every",
      } +
      {
        "de": "2 Sekunden",
        "en": "2 seconds",
      } +
      {
        "de": "5 Sekunden",
        "en": "5 seconds",
      } +
      {
        "de": "10 Sekunden",
        "en": "10 seconds",
      } +
      {
        "de": "20 Sekunden",
        "en": "20 seconds",
      } +
      {
        "de": "30 Sekunden",
        "en": "30 seconds",
      } +
      {
        "de": "1 Minute",
        "en": "1 minute",
      } +
      {
        "de": "Automatisch verbinden",
        "en": "Autoconnect",
      } +
      {
        "de": "Abbrechen",
        "en": "Cancel",
      } +
      {
        "de": "Speichern",
        "en": "Save",
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
        "de": "Gerätname",
        "en": "Device name",
      } +
      {
        "de": "Gerätnamen ändern",
        "en": "Change device name",
      } +
      {
        "de": "Geräte-Info",
        "en": "Device info",
      } +
      {
        "de": "Firmware-Version: ",
        "en": "Firmware version: ",
      } +
      {
        "de": "Nach Bluetooth-Geräten scannen",
        "en": "Scan for nearby Bluetooth devices",
      } +
      {
        "de":
            "Air-Station-Geräte müssen vor der ersten Verwendung konfiguriert werden. Jetzt konfigurieren?",
        "en": "Air Station devices must be configured before first use. Configure now?",
      } +
      {
        "de": "Air Station konfigurieren",
        "en": "Configure Air Station",
      } +
      {
        "de": "Später",
        "en": "Later",
      } +
      {
        "de": "Ja",
        "en": "Yes",
      } +
      {
        "de":
            "Die Konfiguration wurde erfolgreich übertragen. Du kannst die Messwerte deiner Station jetzt im Dashboard einsehen. Es kann einige Minuten dauern, bis die ersten Messwerte eintreffen.",
        "en":
            "The configuration was successfully transferred. You can now view the measurements of your station on the Dashboard. It may take a few minutes for the first measurements to arrive.",
      } +
      {
        "de": "Konfiguration erfolgreich",
        "en": "Configuration Successful",
      } +
      {
        "de": "Gerätnamen ändern",
        "en": "Rename device",
      } +
      {
        "de": "Umbenennen",
        "en": "Rename",
      } +
      {
        "de": "Gerät: ",
        "en": "Device: ",
      } +
      {
        "de": "Adresse: ",
        "en": "Address: ",
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
        "de": "Station neu einrichten",
        "en": "Reconfigure station",
      } +
      {
        "de": 'Möchtest du die WLAN- oder Messeinstellungen der Air Station neu '
            'konfigurieren?',
        "en": 'Do you want to reconfigure the WiFi or measurement settings of the Air Station?',
      } +
      {
        "de": "Abbrechen",
        "en": "Cancel",
      } +
      {
        "de": "Konfigurieren",
        "en": "Configure",
      } +
      {
        "de": "Sensoren:",
        "en": "Sensors:",
      } +
      {
        "de": "Sensirion Sen5x",
        "en": "Sensirion Sen5x",
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
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
