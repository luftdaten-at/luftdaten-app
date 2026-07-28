import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText('de') +
      {
        'de': 'Messwerte konfigurieren',
        'en': 'Configure measurement values',
      } +
      {
        'de': 'Anzuzeigende Daten',
        'en': 'Data to display',
      } +
      {
        'de': 'Anzuzeigende Kacheln',
        'en': 'Tiles to display',
      } +
      {
        'de': 'Mindestens ein Wert muss sichtbar bleiben.',
        'en': 'At least one value must remain visible.',
      } +
      {
        'de': 'Mindestens eine Kachel muss sichtbar bleiben.',
        'en': 'At least one tile must remain visible.',
      } +
      {
        'de': 'Feinstaub',
        'en': 'Particulate matter',
      } +
      {
        'de': 'Klima',
        'en': 'Climate',
      } +
      {
        'de': 'UV-Bestrahlung',
        'en': 'UV irradiance',
      } +
      {
        'de': 'Licht',
        'en': 'Light',
      } +
      {
        'de': 'Umgebung',
        'en': 'Environment',
      } +
      {
        'de': 'UTCI / Behaglichkeit',
        'en': 'UTCI / thermal comfort',
      } +
      {
        'de': 'Gase & Indizes',
        'en': 'Gases & indices',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params, _t);
}
