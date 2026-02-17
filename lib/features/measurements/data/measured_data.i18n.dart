import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "PM0.1",
        "en": "PM0.1",
        "en-US": "PM0.1",
      } +
      {
        "de": "PM1.0",
        "en": "PM1.0",
        "en-US": "PM1.0",
      } +
      {
        "de": "PM2.5",
        "en": "PM2.5",
        "en-US": "PM2.5",
      } +
      {
        "de": "PM4.0",
        "en": "PM4.0",
        "en-US": "PM4.0",
      } +
      {
        "de": "PM10.0",
        "en": "PM10.0",
        "en-US": "PM10.0",
      } +
      {
        "de": "Luftfeuchtigkeit",
        "en": "Humidity",
        "en-US": "Humidity",
      } +
      {
        "de": "Temperatur",
        "en": "Temperature",
        "en-US": "Temperature",
      } +
      {
        "de": "VOCs",
        "en": "VOCs",
        "en-US": "VOCs",
      } +
      {
        "de": "NOx",
        "en": "NOx",
        "en-US": "NOx",
      } +
      {
        "de": "Luftdruck",
        "en": "Air pressure",
        "en-US": "Air pressure",
      } +
      {
        "de": "CO2",
        "en": "CO2",
        "en-US": "CO2",
      } +
      {
        "de": "O3",
        "en": "O3",
        "en-US": "O3",
      } +
      {
        "de": "AQI",
        "en": "AQI",
        "en-US": "AQI",
      } +
      {
        "de": "Gaswiderstand",
        "en": "Gas resistance",
        "en-US": "Gas resistance",
      } +
      {
        "de": "VOCs (absolut)",
        "en": "VOCs (absolute)",
        "en-US": "VOCs (absolute)",
      } +
      {
        "de": "NO2",
        "en": "NO2",
        "en-US": "NO2",
      } +
      {
        "de": "SGP40 Gas-Index (Rohwert)",
        "en": "SGP40 Gas Index (raw)",
        "en-US": "SGP40 Gas Index (raw)",
      } +
      {
        "de": "SGP40 Gas-Index (adjustiert)",
        "en": "SGP40 Gas Index (adjusted)",
        "en-US": "SGP40 Gas Index (adjusted)",
      } +
      {
        "de": "Unbekannt",
        "en": "Unknown",
        "en-US": "Unknown",
      };

  String get i18n => localize(this, _t);
}