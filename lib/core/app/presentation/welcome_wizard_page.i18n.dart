import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Willkommen",
        "en": "Welcome",
      } +
      {
        "de":
            "Für welchen Zweck möchtest Du die Luftdaten.at-App verwenden? Du kannst die App später auch für weitere Zwecke konfigurieren.",
        "en":
            "What do you want to use the Luftdaten.at app for? You can configure the app for other purposes later.",
      } +
      {
        "de": "Die Luftqualität in meiner Umgebung auf der Luftkarte einsehen.",
        "en": "View air quality in my area on the air quality map.",
      } +
      {
        "de": "Mit einem Tragbares Messgerät (z. B. Air aRound) messen.",
        "en": "Measure with a portable device (e.g. Air aRound).",
      } +
      {
        "de": "Ein stationäres Messgerät (z. B. Air Station) konfigurieren.",
        "en": "Configure a stationary device (e.g. Air Station).",
      } +
      {
        "de": "Kamera",
        "en": "Camera",
      } +
      {
        "de": "Die Kamera wird benötigt, um den QR-Code des Messgeräts zu scannen.",
        "en": "The camera is required to scan the device's QR code.",
      } +
      {
        "de": "Bluetooth",
        "en": "Bluetooth",
      } +
      {
        "de": "Bluetooth wird benötigt, um mit dem Messgerät zu kommunizieren.",
        "en": "Bluetooth is required to communicate with the device.",
      } +
      {
        "de": "Standort",
        "en": "Location",
      } +
      {
        "de": "Der Standort wird benötigt, um die Messwerte auf der Karte anzuzeigen.",
        "en": "Location is required to display measurements on the map.",
      } +
      {
        "de": "Standort im Hintergrund",
        "en": "Background location",
      } +
      {
        "de": 'Die Berechtigung „Standortermittlung im Hintergrund" wird benötigt, um auch im '
            'Hintergrund gemessene Messwerte auf der Karte anzuzeigen.',
        "en":
            "Background location permission is required to display measurements taken in the background on the map.",
      } +
      {
        "de": "Akkuoptimierung",
        "en": "Battery optimization",
      } +
      {
        "de":
            "Die Akkuoptimierung wird deaktiviert, um die Messwerte auch im Hintergrund zu aktualisieren.",
        "en":
            "Battery optimization is disabled to keep measurements updated in the background.",
      } +
      {
        "de": "Benachrichtigungen",
        "en": "Notifications",
      } +
      {
        "de":
            "Benachrichtigungen werden benötigt, um über wichtige Ereignisse informiert zu werden.",
        "en":
            "Notifications are required to be informed about important events.",
      } +
      {
        "de": "Unbekannt",
        "en": "Unknown",
      } +
      {
        "de": "Unbekannte Berechtigung",
        "en": "Unknown permission",
      } +
      {
        "de": "Benötigte Berechtigungen",
        "en": "Required permissions",
      } +
      {
        "de": "Diese Berechtigung ist für die Funktion der App notwendig.",
        "en": "This permission is required for the app to function.",
      } +
      {
        "de":
            "Diese Berechtigung ist optional, aber für die optimale Funktion der App empfohlen. Du kannst sie auch später in den Einstellungen der App aktivieren.",
        "en":
            "This permission is optional but recommended for optimal app performance. You can enable it later in the app settings.",
      } +
      {
        "de": "Zurück",
        "en": "Back",
      } +
      {
        "de": "Anfragen",
        "en": "Request",
      } +
      {
        "de": "Möchstest du an einer Luftdaten.at-Messkampagne teilnehmen?",
        "en": "Would you like to take part in a Luftdaten.at measurement campaign?",
      } +
      {
        "de": "Messkampagne beitreten",
        "en": "Join measurement campaign",
      } +
      {
        "de": "Ja, ich habe einen Teilnahmecode",
        "en": "Yes, I have a participation code",
      } +
      {
        "de": "Beitritts-Code eingeben",
        "en": "Enter participation code",
      } +
      {
        "de": "Nein, ich möchte alleine messen",
        "en": "No, I want to measure alone",
      } +
      {
        "de": "Hast du ein Gerät bei der Hand, mit dem du dich verbinden möchtest?",
        "en": "Do you have a device at hand that you want to connect to?",
      } +
      {
        "de": "Ja, Gerät einscannen",
        "en": "Yes, scan device",
      } +
      {
        "de": "Nein, später verbinden",
        "en": "No, connect later",
      };

  String get i18n => localize(this, _t);
}
