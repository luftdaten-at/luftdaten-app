import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText('de') +
      {
        'de': 'Gemessen:',
        'en': 'Measured:',
      } +
      {
        'de': 'MD3 Stat Cards',
        'en': 'MD3 stat cards',
      } +
      {
        'de': 'App-native Tiles',
        'en': 'App-native tiles',
      } +
      {
        'de': 'Color-filled KPI',
        'en': 'Color-filled KPI',
      } +
      {
        'de': 'Gruppierte Sektionen',
        'en': 'Grouped sections',
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
        'de': 'Gase & Indizes',
        'en': 'Gases & indices',
      } +
      {
        'de': 'Layout-Vergleich (Debug)',
        'en': 'Layout comparison (debug)',
      } +
      {
        'de': 'Alle Varianten mit denselben Mock-Messwerten zum Vergleich.',
        'en': 'All variants using the same mock measurements for comparison.',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params, _t);
}
