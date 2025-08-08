import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Route",
        "en": "route",
      } +
      {
        "de": "Messung",
        "en": "measurement",
      } +
      {
        "de": "Neue %s gestartet: %s:%s:%s",
        "en": "New %s started (at %s:%s:%s)",
      } +
      {
        "de": "WHO-Grenzwert-Überschreitung",
        "en": "WHO PM threshold exceeded",
      } +
      {
        "de": "Meldet Überschreitungen der WHO-Feinstaub-Grenzwerte",
        "en": "Reports exceedances of the WHO PM thresholds",
      } +
      {
        "de": "Erhöhte Feinstaubbelastung",
        "en": "Elevated PM levels",
      } +
      {
        "de": "Stark erhöhte Feinstaubbelastung",
        "en": "Very elevated PM levels",
      } +
      {
        "de": "Hintergrund-Service",
        "en": "Background service",
      } +
      {
        "de": "Informiert Dich, wenn die App im Hintergrund mit einem Messgerät kommuniziert.",
        "en": "Notifies you when the app is communicating with a bluetooth device in the background.",
      } +
      {
        "de": "Aktuelle Feinstaubbelastung überschreitet den WHO-%s-Grenzwert. Tippe, um deine Umgebung mit einer Notiz oder einem Bild zu dokumentieren.",
        "en": "Current PM level exceeds the WHO %s threshold. Tap to document your environment with a note or a picture.",
      } +
      {
        "de": "Tagesmittel",
        "en": "daily mean",
      } +
      {
        "de": "Jahresmittel",
        "en": "annual mean",
      }
      +
      {
        "de": "Messung gestartet",
        "en": "Measurement started",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
