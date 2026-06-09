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
        "de": "Temperatur Air Cube (adjustiert)",
        "en": "Adjusted Air Cube temperature",
        "en-US": "Adjusted Air Cube temperature",
      } +
      {
        "de": "UVS",
        "en": "UVS",
        "en-US": "UVS",
      } +
      {
        "de": "Licht",
        "en": "Light",
        "en-US": "Light",
      } +
      {
        "de": "Höhe",
        "en": "Altitude",
        "en-US": "Altitude",
      } +
      {
        "de": "UV-Index",
        "en": "UV Index",
        "en-US": "UV Index",
      } +
      {
        "de": "Beleuchtungsstärke",
        "en": "Illuminance",
        "en-US": "Illuminance",
      } +
      {
        "de": "Beschleunigung X",
        "en": "Acceleration X",
        "en-US": "Acceleration X",
      } +
      {
        "de": "Beschleunigung Y",
        "en": "Acceleration Y",
        "en-US": "Acceleration Y",
      } +
      {
        "de": "Beschleunigung Z",
        "en": "Acceleration Z",
        "en-US": "Acceleration Z",
      } +
      {
        "de": "Gyroskop X",
        "en": "Gyro X",
        "en-US": "Gyro X",
      } +
      {
        "de": "Gyroskop Y",
        "en": "Gyro Y",
        "en-US": "Gyro Y",
      } +
      {
        "de": "Gyroskop Z",
        "en": "Gyro Z",
        "en-US": "Gyro Z",
      } +
      {
        "de": "Thermalbild",
        "en": "Thermal array",
        "en-US": "Thermal array",
      } +
      {
        "de": "Sichtbares Licht",
        "en": "Visible light",
        "en-US": "Visible light",
      } +
      {
        "de": "Infrarot",
        "en": "Infrared",
        "en-US": "Infrared",
      } +
      {
        "de": "Vollspektrum",
        "en": "Full spectrum",
        "en-US": "Full spectrum",
      } +
      {
        "de": "Roh-Luminanz",
        "en": "Raw luminosity",
        "en-US": "Raw luminosity",
      } +
      {
        "de": "Unbekannt",
        "en": "Unknown",
        "en-US": "Unknown",
      };

  String get i18n => localize(this, _t);
}