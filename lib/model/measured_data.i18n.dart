import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "PM0.1",
        "en": "PM0.1",
      } +
      {
        "de": "PM1.0",
        "en": "PM1.0",
      } +
      {
        "de": "PM2.5",
        "en": "PM2.5",
      } +
      {
        "de": "PM4.0",
        "en": "PM4.0",
      } +
      {
        "de": "PM10.0",
        "en": "PM10.0",
      } +
      {
        "de": "Luftfeuchtigkeit",
        "en": "Humidity",
      } +
      {
        "de": "Temperatur",
        "en": "Temperature",
      } +
      {
        "de": "VOCs",
        "en": "VOCs",
      } +
      {
        "de": "NOx",
        "en": "NOx",
      } +
      {
        "de": "Luftdruck",
        "en": "Air pressure",
      };

  String get i18n => localize(this, _t);
}