import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText('de') +
      {
        'de': 'Kalibrierung',
        'en': 'Calibration',
      } +
      {
        'de': 'Korrekturen werden in der App gespeichert und auf Live-Messungen angewendet.',
        'en': 'Corrections are stored in the app and applied to live measurements.',
      } +
      {
        'de': 'CO₂ (Frischluft)',
        'en': 'CO₂ (fresh air)',
      } +
      {
        'de': 'Frischluft-Kalibrierung',
        'en': 'Fresh-air calibration',
      } +
      {
        'de': 'Offset: %s ppm',
        'en': 'Offset: %s ppm',
      } +
      {
        'de': 'Kein Offset gesetzt',
        'en': 'No offset set',
      } +
      {
        'de': 'Offset löschen',
        'en': 'Clear offset',
      } +
      {
        'de': 'Firmware-Neukalibrierung bald verfügbar',
        'en': 'Firmware recalibration coming soon',
      } +
      {
        'de': 'Körperwärme (UTCI)',
        'en': 'Body heat (UTCI)',
      } +
      {
        'de': 'Automatische Kalibrierung über Außen-Nachtmessungen.',
        'en': 'Automatic calibration from outdoor night measurements.',
      } +
      {
        'de': 'Proben: %s / %s',
        'en': 'Samples: %s / %s',
      } +
      {
        'de': 'ΔT_body: %s K',
        'en': 'ΔT_body: %s K',
      } +
      {
        'de': 'Noch keine Kalibrierung',
        'en': 'Not calibrated yet',
      } +
      {
        'de': 'Qualität A (kalibriert)',
        'en': 'Quality A (calibrated)',
      } +
      {
        'de': 'Qualität B (Fallback)',
        'en': 'Quality B (fallback)',
      } +
      {
        'de': 'Kalibrierung sammelt…',
        'en': 'Collecting calibration…',
      } +
      {
        'de': 'Kalibrierung zurücksetzen',
        'en': 'Reset calibration',
      } +
      {
        'de': 'Temperatur-Offset (%s)',
        'en': 'Temperature offset (%s)',
      } +
      {
        'de': 'Feuchte-Offset (%s)',
        'en': 'Humidity offset (%s)',
      } +
      {
        'de': 'Offset in °C',
        'en': 'Offset in °C',
      } +
      {
        'de': 'Offset in % RH',
        'en': 'Offset in % RH',
      } +
      {
        'de': 'Speichern',
        'en': 'Save',
      } +
      {
        'de': 'Zurücksetzen',
        'en': 'Reset',
      } +
      {
        'de': 'CO₂-Frischluft-Kalibrierung',
        'en': 'CO₂ fresh-air calibration',
      } +
      {
        'de': 'Stelle das Gerät in gut belüftete Frischluft (idealerweise im Freien) und warte, bis der CO₂-Wert stabil ist.',
        'en': 'Place the device in well-ventilated fresh air (ideally outdoors) and wait until the CO₂ reading stabilises.',
      } +
      {
        'de': 'Referenz-CO₂ (ppm)',
        'en': 'Reference CO₂ (ppm)',
      } +
      {
        'de': 'Messung starten',
        'en': 'Start measurement',
      } +
      {
        'de': 'Gemessener CO₂-Wert: %s ppm',
        'en': 'Measured CO₂ value: %s ppm',
      } +
      {
        'de': 'Offset %s ppm wird angewendet.',
        'en': 'Offset of %s ppm will be applied.',
      } +
      {
        'de': 'Kein CO₂-Wert vom Gerät empfangen.',
        'en': 'No CO₂ value received from the device.',
      } +
      {
        'de': 'Messung fehlgeschlagen: %s',
        'en': 'Measurement failed: %s',
      } +
      {
        'de': 'App-seitige Korrektur — ersetzt keine sensorinterne Forced Recalibration.',
        'en': 'App-side correction — does not replace in-sensor forced recalibration.',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params, _t);
}
