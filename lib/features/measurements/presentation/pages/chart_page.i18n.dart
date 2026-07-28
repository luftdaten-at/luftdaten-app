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
        "de": "Gemessen:",
        "en": "Measured:",
      } +
      {
        "de": "Messwerte konfigurieren",
        "en": "Configure measurements",
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
      } +
      {
        "de": "µW/cm²",
        "en": "µW/cm²",
      } +
      {
        "de": "UVA",
        "en": "UVA",
      } +
      {
        "de": "UVB",
        "en": "UVB",
      } +
      {
        "de": "UVC",
        "en": "UVC",
      } +
      {
        "de": "UV-Index",
        "en": "UV Index",
      } +
      {
        "de": "UV-Bestrahlung",
        "en": "UV irradiance",
      } +
      {
        "de": "Beleuchtungsstärke",
        "en": "Illuminance",
      } +
      {
        "de": "lx",
        "en": "lx",
      } +
      {
        "de": "Lichtkanäle",
        "en": "Light channels",
      } +
      {
        "de": "IR-Anteil",
        "en": "IR share",
      } +
      {
        "de": "Sichtbares Licht",
        "en": "Visible light",
      } +
      {
        "de": "Infrarot",
        "en": "Infrared",
      } +
      {
        "de": "Vollspektrum",
        "en": "Full spectrum",
      } +
      {
        "de": "Umgebung",
        "en": "Environment",
      } +
      {
        "de": "Außen",
        "en": "Outdoor",
      } +
      {
        "de": "Innen",
        "en": "Indoor",
      } +
      {
        "de": "Fensterplatz",
        "en": "Near window",
      } +
      {
        "de": "Unbekannt",
        "en": "Unknown",
      } +
      {
        "de": "Konfidenz",
        "en": "Confidence",
      } +
      {
        "de": "Score",
        "en": "Score",
      } +
      {
        "de": "Innen/Außen-Score",
        "en": "Indoor/outdoor score",
      } +
      {
        "de": "Klassifikationsmerkmale",
        "en": "Classification features",
      } +
      {
        "de": "UV-Anteil (k_UV)",
        "en": "UV fraction (k_UV)",
      } +
      {
        "de": "Glasindikator (UVB/UVA)",
        "en": "Glass indicator (UVB/UVA)",
      } +
      {
        "de": "UTCI",
        "en": "UTCI",
      } +
      {
        "de": "Behaglichkeit",
        "en": "Thermal comfort",
      } +
      {
        "de": "Thermische Treiber",
        "en": "Thermal drivers",
      } +
      {
        "de": "Sonnenanteil",
        "en": "Sun exposure",
      } +
      {
        "de": "Treiber",
        "en": "Driver",
      } +
      {
        "de": "Vorbehalt",
        "en": "Caveat",
      } +
      {
        "de": "Stand",
        "en": "As of",
      } +
      {
        "de": "T_mrt",
        "en": "Mean radiant temp.",
      } +
      {
        "de": "Extreme Hitzebelastung",
        "en": "Extreme heat stress",
      } +
      {
        "de": "Sehr starke Hitzebelastung",
        "en": "Very strong heat stress",
      } +
      {
        "de": "Starke Hitzebelastung",
        "en": "Strong heat stress",
      } +
      {
        "de": "Mäßige Hitzebelastung",
        "en": "Moderate heat stress",
      } +
      {
        "de": "Keine thermische Belastung",
        "en": "No thermal stress",
      } +
      {
        "de": "Leichte Kältebelastung",
        "en": "Slight cold stress",
      } +
      {
        "de": "Mäßige Kältebelastung",
        "en": "Moderate cold stress",
      } +
      {
        "de": "Starke Kältebelastung",
        "en": "Strong cold stress",
      } +
      {
        "de": "Sehr starke Kältebelastung",
        "en": "Very strong cold stress",
      } +
      {
        "de": "Extreme Kältebelastung",
        "en": "Extreme cold stress",
      } +
      {
        "de": "Kalt",
        "en": "Cold",
      } +
      {
        "de": "Etwas kalt",
        "en": "Slightly cold",
      } +
      {
        "de": "Neutral",
        "en": "Neutral",
      } +
      {
        "de": "Etwas warm",
        "en": "Slightly warm",
      } +
      {
        "de": "Warm",
        "en": "Warm",
      } +
      {
        "de": "Feinstaub",
        "en": "Particulate Matter",
      } +
      {
        "de": "Unbekanntes Gerät",
        "en": "Unknown device",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params, _t);
}