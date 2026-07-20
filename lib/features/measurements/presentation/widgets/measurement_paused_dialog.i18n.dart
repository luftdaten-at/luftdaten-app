import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText('de') +
      {
        'de': 'Messung pausiert',
        'en': 'Measurement paused',
        'en-US': 'Measurement paused',
      } +
      {
        'de':
            'Die Bluetooth-Verbindung zum Messgerät wurde unterbrochen. '
                'Die Messung ist pausiert — es wird versucht, die Verbindung wiederherzustellen.',
        'en':
            'The Bluetooth connection to the measuring device was lost. '
                'The measurement is paused — trying to reconnect.',
        'en-US':
            'The Bluetooth connection to the measuring device was lost. '
                'The measurement is paused — trying to reconnect.',
      } +
      {
        'de': 'Messung beenden',
        'en': 'Stop measurement',
        'en-US': 'Stop measurement',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
