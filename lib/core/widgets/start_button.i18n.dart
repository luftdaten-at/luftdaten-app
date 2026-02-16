import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {"de": "Messung beenden", "en": "End measurement"} +
      {"de": "Messung starten", "en": "Start measurement"} +
      {"de": "Messung fortsetzen", "en": "Continue measurement"} +
      {"de": "Route fortsetzen?", "en": "Continue existing route?"} +
      {
        "de": "Es existiert bereits eine Route. Soll die alte Route fortgesetzt werden "
            "oder eine neue Route gestartet werden?",
        "en": "Continue existing route, or start a new one?",
      } +
      {"de": "Fortsetzen", "en": "Continue"} +
      {"de": "Neue Route", "en": "New route"} +
      {"de": "Aktuelle Messung beenden?", "en": "End current measurement?"} +
      {"de": "Beenden", "en": "End now"} +
      {"de": "Transportmittel ändern", "en": "Change mode of transport"} +
      {"de": "Transportmittel wählen", "en": "Select mode of transport"} +
      {"de": "Zu Fuß", "en": "On foot"} +
      {"de": "Fahrrad/Roller", "en": "Bike/Scooter"} +
      {"de": "Öffis", "en": "Public transport"} +
      {"de": "Auto", "en": "Car"};

  String get i18n => localize(this, _t);
}
