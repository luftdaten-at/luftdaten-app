import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {

  static final _t = Translations.byText("de") +
      {
        "de": "Willkommen",
        "en": "Welcome",
      } +
      {
        "de": "Zurück",
        "en": "Go back",
      } +
      {
        "de": "Benötigte Berechtigungen:",
        "en": "Required permissions:",
      } +
      {
        "de": "Empfohlene Berechtigungen:",
        "en": "Recommended permissions:",
      } +
      {
        "de": "Andere Berechtigungen:",
        "en": "Other permissions:",
      } +
      {
        "de": "Ohne",
        "en": "Continue without",
      } +
      {
        "de": "empfohlene",
        "en": "recommended",
      } +
      {
        "de": "benötigte",
        "en": "required",
      } +
      {
        "de": "Berechtigungen fortfahren? Fehlende Berechtigungen können zu unerwartetem Verhalten der App und etwaigen Messgeräten führen.",
        "en": "permissions? Missing permissions can cause unexpected app behaviour.",
      } +
      {
        "de": "Fortfahren?",
        "en": "Continue?",
      } +
      {
        "de": "Weiter",
        "en": "Continue",
      } +
      {
        "de": "Um deine Luftdaten.at-Messgeräte zu verwenden, sind bestimmte Berechtigungen notwendig.",
        "en": "Certain app permissions are required to use your Luftdaten.at devices.",
      } +
      {
        "de": "Für welche der folgenden Geräte möchtest du die App verwenden?",
        "en": "Which devices would you like to use with this app?",
      } +
      {
        "de": "Air aRound (tragbares Messgerät)",
        "en": "Air aRound (portable device)",
      } +
      {
        "de": "Air Station (stationäres Messgerät)",
        "en": "Air Station (stationary device)",
      } +
      {
        "de": "Keine",
        "en": "None",
      } +
      {
        "de": "Benötigt für:",
        "en": "Required for:",
      } +
      {
        "de": "Empfohlen für:",
        "en": "Recommended for:",
      } +
      {
        "de": "Anfragen",
        "en": "Request",
      } +
      {
        "de": "Bluetooth (Geräte in der Nähe)",
        "en": "Bluetooth (Nearby Devices)",
      } +
      {
        "de": "Erlaubt es der App, sich mit Bluetooth Low Energy (BLE) Geräten in der Nähe zu verbinden.",
        "en": "Allows the app to connect to nearby Bluetooth Low Energy (BLE) devices.",
      } +
      {
        "de": "Steuerung der Messung und Auslesen der Messdaten",
        "en": "Controlling measurements and reading measured data",
      } +
      {
        "de": "Einrichten des Geräts",
        "en": "Device set-up",
      } +
      {
        "de": "Standortermittlung",
        "en": "Location",
      } +
      {
        "de": "Erlaubt es der App, deinen Standort zu ermitteln, während die App geöffnet ist.",
        "en": "Allows the app to determine location while the app is foregrounded.",
      } +
      {
        "de": "Verbinden von Messdaten mit Standorten",
        "en": "Correlation of measured data with locations",
      } +
      {
        "de": "Anzeigen deines Standorts auf der Luftkarte",
        "en": "Displaying your location on the map",
      } +
      {
        "de": "Standortermittlung im Hintergrund",
        "en": "Background location",
      } +
      {
        "de": 'Erlaubt es der App, deinen Standort auch dann zu ermitteln, wenn die App nicht '
            'geöffnet ist (z. B., wenn du während einer Messung deinen Handybildschirm ausschaltest.',
        "en": "Allows the app to determine your location in the background (for example, "
            "when the screen is turned off during a measurement).",
      } +
      {
        "de": "Verbinden von Messdaten mit Standorten, während Bildschirm ausgeschaltet ist",
        "en": "Correlation of measured data with locations also when phone screen is off.",
      } +
      {
        "de": "Akku-Optimierung deaktivieren",
        "en": "Battery optimization",
      } +
      {
        "de": 'Nimmt die App von Androids Akku-Optimisierung aus. Akku-Optimisierung kann dazu führen, '
            'dass Messvorgänge unerwartet abgebrochen werden, weil das System die App während der '
            'Messung schließt.',
        "en": "Exempts the app from Android's system battery optimization. This can avoid unexpected "
            "interruptions in measured data.",
      } +
      {
        "de": "Stabilen Messvorgang",
        "en": "Stable measurements",
      } +
      {
        "de": "Kamera",
        "en": "Camera",
      } +
      {
        "de": 'Ermöglicht es der App, einen QR-Code-Scanner für das schnellere Verbinden '
            'mit Geräten anzubieten.',
        "en": "Allows the app to provide a QR code scanner for quick device set-up.",
      } +
      {
        "de": "Verbindung zum Gerät mittels QR-Code",
        "en": "Connection to device by QR code",
      } +
      {
        "de": "Benachrichtigungen",
        "en": "Notifications",
      } +
      {
        "de": "Erlaubt es der App, Benachrichtigungen zu senden.",
        "en": "Allows the app to send notifications.",
      } +
      {
        "de": "Meldung von Regionen erhöhter Luftverschmutzung",
        "en": "Altering you to regions of high air pollution",
      } +
      {
        "de": "Meldung von Zeiten erhöhter Luftverschmutzung",
        "en": "Altering you to times of high air pollution",
      } +
      {
        "de": "Statusmeldungen über die lokale Luftqualität",
        "en": "Altering you to patterns in local air quality",
      };

  String get i18n => localize(this, _t);
}