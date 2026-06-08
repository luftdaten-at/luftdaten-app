import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText('de') +
      {
        'de': 'Mock-Messdaten',
        'en': 'Mock measurement data',
      } +
      {
        'de': 'Nur Debug-Build. Fügt Test-Messungen für Karte und Messwerte hinzu.',
        'en': 'Debug builds only. Injects test measurements for map and charts.',
      } +
      {
        'de': 'Voreinstellungen (GPS-Pfad)',
        'en': 'Presets (GPS trail)',
      } +
      {
        'de': 'Gute Luft',
        'en': 'Good air',
      } +
      {
        'de': 'Niedrige PM-Werte entlang eines kurzen Wegs.',
        'en': 'Low PM values along a short path.',
      } +
      {
        'de': 'Schlechte Luft',
        'en': 'Bad air',
      } +
      {
        'de': 'Hohe PM-Werte zum Testen von Warnungen und Legende.',
        'en': 'High PM values for testing alerts and legend colours.',
      } +
      {
        'de': 'Farbverlauf (Karte)',
        'en': 'Colour gradient (map)',
      } +
      {
        'de': 'PM steigt von gut nach schlecht — ideal für die Farblegende.',
        'en': 'PM ramps from good to bad — ideal for the colour legend.',
      } +
      {
        'de': 'Live-Mock-Messung',
        'en': 'Live mock measurement',
      } +
      {
        'de': 'Fügt alle 10 Sekunden synthetische Messpunkte hinzu.',
        'en': 'Adds synthetic measurement points every 10 seconds.',
      } +
      {
        'de': 'Live-Mock-Messung starten',
        'en': 'Start live mock measurement',
      } +
      {
        'de': 'Live-Mock-Messung stoppen',
        'en': 'Stop live mock measurement',
      } +
      {
        'de': 'Mock-Messdaten entfernen',
        'en': 'Remove mock measurement data',
      } +
      {
        'de': 'Entfernt geladene Mock-Pfade und stoppt die Live-Mock-Messung.',
        'en': 'Removes loaded mock trails and stops the live mock measurement.',
      } +
      {
        'de': 'Status',
        'en': 'Status',
      } +
      {
        'de': 'Geladene Mock-Pfade: %s',
        'en': 'Loaded mock trails: %s',
      } +
      {
        'de': 'Live-Mock aktiv (%s Punkte)',
        'en': 'Live mock active (%s points)',
      } +
      {
        'de': 'Live-Mock inaktiv',
        'en': 'Live mock inactive',
      } +
      {
        'de': 'Mock-Pfad hinzugefügt.',
        'en': 'Mock trail added.',
      } +
      {
        'de': 'Eine echte Messung läuft bereits.',
        'en': 'A real measurement is already running.',
      } +
      {
        'de':
            'Neu geladene Messpunkte zur aktuellen Anzeige hinzufügen oder aktuelle Anzeige überschreiben?',
        'en':
            'Add newly loaded measurement points to the current display or overwrite current display?',
      } +
      {
        'de': 'Daten hinzufügen',
        'en': 'Add or Overwrite',
      } +
      {
        'de': 'Hinzufügen',
        'en': 'Add',
      } +
      {
        'de': 'Überschreiben',
        'en': 'Overwrite',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
