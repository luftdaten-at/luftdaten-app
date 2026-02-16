import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": 'Air Station Konfiguration',
        "en": 'Air Station Configuration',
      } +
      {
        "de": 'Verbinde zu Gerät...',
        "en": 'Connecting to device...',
      } +
      {
        "de": 'Lade Konfiguration von Gerät...',
        "en": 'Loading configuration from device...',
      } +
      {
        "de": 'Konfiguration wird übermittelt...',
        "en": 'Configuration is being transmitted...',
      } +
      {
        "de": 'Verbindung fehlgeschlagen',
        "en": 'Connection Failed',
      } +
      {
        "de": 'Um dich mit der Station zu verbinden, stelle sicher, dass:',
        "en": 'To connect to the station, make sure that:',
      } +
      {
        "de": '• Bluetooth auf deinem Mobilgerät eingeschalten ist.',
        "en": '• Bluetooth is turned on on your mobile device.',
      } +
      {
        "de": '• Die Air Station im Konfigurations-Modus ist (erkenntlich durch die blau leuchtende Status-LED). Dieser wird mit dem BT-Button am Gerät aktiviert.',
        "en": '• The Air Station is in configuration mode (indicated by the blue status LED). This is activated by pressing the BT button on the device.',
      } +
      {
        "de": 'Erneut versuchen',
        "en": 'Retry',
      } +
      {
        "de": 'Einstellungen',
        "en": 'Settings',
      } +
      {
        "de": 'Automatische Updates über Wifi',
        "en": 'Automatic updates over Wifi',
      } +
      {
        "de": 'Energiesparmodus',
        "en": 'Energy saving mode',
      } +
      {
        "de": 'Messintervall',
        "en": 'Measurement interval',
      } +
      {
        "de": 'Messen jede',
        "en": 'Measure every',
      } +
      {
        "de": 'Wifi-Zugangsdaten',
        "en": 'Wifi Access Details',
      } +
      {
        "de": 'Aus Sicherheitsgründen werden gespeicherte Wifi-Passwörter nicht angezeigt.',
        "en": 'For security reasons, stored Wifi passwords are not displayed.',
      } +
      {
        "de": 'Möchtest du die Station mit einem neuen Wifi-Netzwerk verbinden?',
        "en": 'Are you connecting the station to a new Wifi network?',
      } +
      {
        "de": 'Ja',
        "en": 'Yes',
      } +
      {
        "de": 'Nein',
        "en": 'No',
      } +
      {
        "de": 'SSID (Netzwerkname)',
        "en": 'SSID (Network name)',
      } +
      {
        "de": 'Passwort',
        "en": 'Password',
      } +
      {
        "de": 'Konfiguration senden',
        "en": 'Send configuration',
      } +
      {
        "de": 'Bitte überprüfe deine Wifi-Daten-Eingaben.',
        "en": 'Please check your Wifi data entries.',
      } +
      {
        "de": 'Ungültige Wifi-Daten',
        "en": 'Invalid Wifi data',
      } +
      {
        "de": 'Die Konfiguration wurde erfolgreich übermittelt.',
        "en": 'The configuration was successfully transmitted.',
      } +
      {
        "de": 'Gerät konfiguriert',
        "en": 'Device configured',
      } +
      {
        "de": 'Die Konfiguration konnte nicht übermittelt werden. Bitte überprüfe deine Verbindung zur Air Station.',
        "en": 'The configuration could not be transmitted. Please check your connection to the Air Station.',
      } +
      {
        "de": 'Fehler während der Übermittlung.',
      } +
      {
        "de": 'Übermittlungsfehler',
        "en": 'Transmission error',
      } +
      {
        "de": 'An (Empfohlen)',
        "en": 'On (Recommended)',
      } +
      {
        "de": 'Nur kritische',
        "en": 'Only critical',
      } +
      {
        "de": 'Aus',
        "en": 'Off',
      } +
      {
        "de": '30 Sekunden',
        "en": '30 seconds',
      } +
      {
        "de": '1 Minute',
        "en": '1 minute',
      } +
      {
        "de": '3 Minuten',
        "en": '3 minutes',
      } +
      {
        "de": '5 Minuten (Empfohlen)',
        "en": '5 minutes (Recommended)',
      } +
      {
        "de": '10 Minuten',
        "en": '10 minutes',
      } +
      {
        "de": '15 Minuten',
        "en": '15 minutes',
      } +
      {
        "de": '30 Minuten',
        "en": '30 minutes',
      } +
      {
        "de": '1 Stunde',
        "en": '1 hour',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
