import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": 'Zum Datenempfang ist die Berechtigung, Bluetooth zu verwenden, um Geräte in der '
            'Nähe zu finden, notwendig.',
        "en": 'To receive data, the app must have permission to use Bluetooth.',
      } +
      {"de": "Einstellungen öffnen", "en": "Open settings"} +
      {"de": "OK", "en": "OK"} +
      {
        "de": 'Damit Messdaten mit Standorten verbunden werden können, ist die Standort-Ermitterungs-'
            'Berechtigung empfohlen.',
        "en": 'To connect measurement data to locations, the app must have permission to use device location.',
      } +
      {"de": "Standortberechtigung", "en": "Location permission"} +
      {
        "de": 'Damit Messdaten auch im Hintergrund aufgezeichnet werden können, ist die '
            'Berechtigung "Standortermittlung im Hintergrund" empfohlen.',
        "en": 'To record measurement data in the background, the app must have permission to use device location in the background.',
      } +
      {"de": "Bluetooth benötigt", "en": "Bluetooth required"} +
      {
        "de": "Bluetooth muss eingeschaltet sein, um Verbindung zu Messgeräten herzustellen.",
        "en": "Bluetooth must be enabled to connect to measurement devices.",
      } +
      {"de": "Gerät auswählen", "en": "Select device"} +
      {"de": "Verbindung wird hergestellt...", "en": "Connecting..."} +
      {
        "de": "Verbindung zu Bluetooth-Gerät konnte nicht hergestellt werden.",
        "en": "Could not connect to Bluetooth device.",
      } +
      {"de": "Verbindung getrennt", "en": "Disconnected"} +
      {
        "de": "Die Verbindung zum Bluetooth-Gerät wurde getrennt.",
        "en": "The connection to the Bluetooth device has ended.",
      } +
      {"de": "Nein", "en": "No"} +
      {"de": "Ja", "en": "Yes"} +
      {"de": "Schließen", "en": "Close"} +
      {"de": "Abbrechen", "en": "Cancel"} +
      {"de": "Speichern", "en": "Save"} +
      {"de": "Löschen", "en": "Delete"};

  String get i18n => localize(this, _t);
}
