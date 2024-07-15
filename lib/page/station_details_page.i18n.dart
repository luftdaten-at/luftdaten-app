import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Station #%s",
        "en": "Station #%s",
      } +
      {
        "de": "Synchronisieren",
        "en": "Sync",
      } +
      {
        "de": "Keine Daten verfügbar.",
        "en": "No data available.",
      } +
      {
        "de": "Tippe auf das Sync-Icon rechts oben, um nach neuen Daten zu suchen.",
        "en": "Tap the sync icon in the top right corner to search for new data.",
      } +
      {
        "de": "Daten der letzten:",
        "en": "Show data for the past:",
      } +
      {
        "de": "24 Stunden",
        "en": "24 hours",
      } +
      {
        "de": "7 Tage",
        "en": "7 days",
      } +
      {
        "de": "1 Monat",
        "en": "1 month",
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
        "de": "Durchschnittswerte der letzten 7 Tage (μg/m³):",
        "en": "Means for the past 7 days (μg/m³):",
      } +
      {
        "de": "Richtwerte der WHO (μg/m³, 24h-Mittel):",
        "en": "WHO guidelines (μg/m³, 24h mean):",
      } +
      {
        "de": "PM2.5 überschritten an %s Tagen/Woche.",
        "en": "PM2.5 guidelines exceeded on %s days/week.",
      } +
      {
        "de": "PM10 überschritten an %s Tagen/Woche.",
        "en": "PM10 guidelines exceeded on %s days/week.",
      } +
      {
        "de": "Richtwerte der WHO (μg/m³, Jahresmittel):",
        "en": "WHO guidelines (μg/m³, annual mean):",
      } +
      {
        "de": "Aktuelle Messwerte (μg/m³):",
        "en": "Most recent measurements (μg/m³):",
      } +
      {
        "de": "Gemessen",
        "en": "Measured at",
      } +
      {
        "de": "(vor %s)",
        "en": "(%s ago)",
      } +
      {
        "de": "Innerhalb des Richtwerts",
        "en": "Within guidelines",
      } +
      {
        "de": "Überschreitet Richtwert",
        "en": "Exceeds guidelines",
      } +
      {
        "de": "Richtwert anzeigen",
        "en": "Show guidelines",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}