import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {

  static final _t = Translations.byText("de") +
      {
        "de": 'Auf dieser Seite können Messwerte von tragbaren Messgeräten ausgewertet werden. Füge unter „Geräte“ ein tragbares Messgerät hinzu, oder importiere Messdaten aus JSON oder CSV im Menü rechts oben.',
        "en": 'This page is for viewing measurements from portable devices. To get started, add a portable device under "Devices", or import measurement data from JSON or CSV files in the menu in the top right corner.',
      } +
      {
        "de": 'Drücke auf „Messung starten“, um Daten aufzunehmen, oder importiere Messdaten aus früheren Messungen, JSON- oder CSV-Datein im Menü rechts oben.',
        "en": 'Press "Start Measurement" to record data, or import measurement data from previous measurements or external JSON or CSV files in the menu in the top right corner.',
      } +
      {
        "de": "Feinstaubbelastung",
        "en": "Particulate Matter",
      } +
      {
        "de": "Konzentration (μg/m³)",
        "en": "Concentration (μg/m³)",
      } +
      {
        "de": "Temperatur und relative Luftfeuchtigkeit",
        "en": "Temperature and Relative Humidity",
      } +
      {
        "de": "°C oder %",
        "en": "°C or %",
      } +
      {
        "de": "Temperatur",
        "en": "Temperature",
      } +
      {
        "de": "Luftfeuchtigkeit",
        "en": "Relative Humidity",
      } +
      {
        "de": "Flüchtige organische Verbindungen (VOC)",
        "en": "Volatile Organic Compounds (VOC)",
      } +
      {
        "de": "Index (%)",
        "en": "Index (%)",
      } +
      {
        "de": "Stickoxide (NOx)",
        "en": "Nitrous Oxides (NOx)",
      } +
      {
        "de": "Vollbildmodus beenden",
        "en": "Leave full-screen mode",
      } +
      {
        "de": "Vollbildmodus",
        "en": "Enter full-screen mode",
      } +
      {
        "de": "Batteriestatus",
        "en": "Battery status",
      } +
      {
        "de": "Ladestatus (%)",
        "en": "Charge status (%)",
      } +
      {
        "de": "Mittelwert",
        "en": "Mean",
      } +
      {
        "de": "Letzte Messwerte",
        "en": "Latest measurements",
      } +
      {
        "de": "Batteriespannung (V)",
        "en": "Battery voltage (V)",
      } +
      {
        "de": "%s in %s",
        "en": "%s in %s",
      } +
      {
        "de": "Batteriespannung",
        "en": "Battery voltage",
      } +
      {
        "de": "Luftdruck",
        "en": "Air pressure",
      } +
      {
        "de": "Air Quality Index",
        "en": "Air Quality Index",
      } +
      {
        "de": "Gaswiderstand",
        "en": "Gas resistance",
      } +
      {
        "de": "μg/m³",
        "en": "μg/m³",
      } +
      {
        "de": "hPa",
        "en": "hPa",
      } +
      {
        "de": "ppm",
        "en": "ppm",
      } +
      {
        "de": "ppb",
        "en": "ppb",
      } +
      {
        "de": "Index",
        "en": "Index",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params, _t);
}