import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {

  static final _t = Translations.byText("de") +
      {
        "de": 'Meine Air-Station-Geräte:',
        "en": 'My Air Station Devices:',
      } +
      {
        "de": 'Du hast noch keine Air Station konfiguriert.',
        "en": 'You have not configured any Air Stations yet.',
      } +
      {
        "de": 'Neues Gerät hinzufügen',
        "en": 'Add new device',
      } +
      {
        "de": 'Meine Favoriten:',
        "en": 'My Favorites:',
      } +
      {
        "de": 'Füge Messstationen von der Luftkarte zu deinen Favoriten hinzu, um einen schnellen Überblick über die Luftqualität in deiner Umgebung zu bekommen. Tippe dazu auf eine Messstation auf der Luftkarte und wähle das Lesezeichen im rechts oberen Eck des Dialogfeldes.',
        "en": 'Add measurement stations from the map to your favorites to get a quick overview of the air quality in your area. To do this, tap on any measurement station on the map and tap the bookmark in the upper right corner of the dialog box.',
      } +
      {
        "de": 'Zur Luftkarte',
        "en": 'To the map',
      } +
      {
        "de": 'Tragbare Messungen:',
        "en": 'Portable Measurements:',
      } +
      {
        "de": 'Du hast noch keine tragbaren Messgeräte (z. B. Air aRound) konfiguriert.',
        "en": 'You have not configured any portable measurement devices (e.g. Air aRound) yet.',
      } +
      {
        "de": 'Neues Gerät hinzufügen',
        "en": 'Add new device',
      } +
      {
        "de": 'Messungen können auf den Luftkarte- und Messwerte-Seiten gestartet und beendet werden.',
        "en": 'Measurements can be started and stopped on the Map and Data pages.',
      } +
      {
        "de": 'Zur Messwerte-Seite',
        "en": 'To Data page',
      } +
      {
        "de": 'Reiter verstecken?',
        "en": 'Hide tab?',
      } +
      {
        "de": 'Diesen Reiter verstecken? Versteckte Reiter können in den Einstellungen wieder aktiviert werden.',
        "en": 'Hide this tab? Hidden tabs can be reactivated in the settings.',
      } +
      {
        "de": 'Abbrechen',
        "en": 'Cancel',
      } +
      {
        "de": 'Verstecken',
        "en": 'Hide',
      } +
      {
        "de": 'Archivieren',
        "en": 'Archive',
      } +
      {
        "de": 'Mehr lesen',
        "en": 'Read more',
      } +
      {
        "de": 'Neues in der App:',
        "en": 'App news:',
      } +
      {
        "de": 'Zur Messwerte-Seite',
        "en": 'To Data page',
      } +
      {
        "de": 'An Workshop teilnehmen',
        "en": 'Take part in a workshop',
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
        "de": "Workshop-Details",
        "en": "Workshop details",
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