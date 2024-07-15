import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {

  static final _t = Translations.byText("de") +
      {
        "de": "Gemessen: ",
        "en": "Measured:",
      } +
      {
        "de": "Feinstaub (μg/m³)",
        "en": "Particulate matter (μg/m³)",
      } +
      {
        "de": "NOx-Index (Relativ zu 100)",
        "en": "NOx-Index (Relative to 100)",
      } +
      {
        "de": "VOC-Index (Relativ zu 100)",
        "en": "VOC-Index (Relative to 100)",
      } +
      {
        "de": "Temperatur",
        "en": "Temperature",
      } +
      {
        "de": "Relative Luftfeuchtigkeit",
        "en": "Relative humidity",
      } +
      {
        "de": "Notizen hinzufügen",
        "en": "Add notes",
      };

  String get i18n => localize(this, _t);
}