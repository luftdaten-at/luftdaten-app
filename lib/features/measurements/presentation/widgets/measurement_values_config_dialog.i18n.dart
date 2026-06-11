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
        'de': 'Mindestens ein Wert muss sichtbar bleiben.',
        'en': 'At least one value must remain visible.',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params, _t);
}
