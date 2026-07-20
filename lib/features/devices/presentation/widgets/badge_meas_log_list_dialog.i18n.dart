import 'package:i18n_extension/i18n_extension.dart';

extension BadgeMeasLogListDialogI18n on String {
  static final _t = Translations.byText('de') +
      {
        'de': 'Messungen',
        'en': 'Measurements',
      } +
      {
        'de': 'Messung %s',
        'en': 'Measurement %s',
      } +
      {
        'de': 'Messungen importieren',
        'en': 'Import measurements',
      } +
      {
        'de': 'Geschätzte Zeitpunkte (30-Sekunden-Intervall).',
        'en': 'Estimated timestamps (30-second interval).',
      } +
      {
        'de': 'Schließen',
        'en': 'Close',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
