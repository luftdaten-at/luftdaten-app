import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText('de') +
      {
        'de': 'Diagramm konfigurieren',
        'en': 'Configure chart',
      } +
      {
        'de': 'Anzuzeigende Daten',
        'en': 'Data to display',
      } +
      {
        'de': 'Mittelwert',
        'en': 'Mean',
      } +
      {
        'de': 'Mindestens eine Reihe muss sichtbar bleiben.',
        'en': 'At least one series must remain visible.',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params, _t);
}
