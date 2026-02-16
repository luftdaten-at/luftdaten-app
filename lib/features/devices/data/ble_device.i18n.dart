import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Gerät %s kommuniziert über eine nicht erkanntes Protokoll (Version %i). Bitte update deine App.",
        "en": "Device %s communicates via an unrecognized protocol (version %i). Please update your app.",
      } +
      {
        "de": "Inkompatible Firmware",
        "en": "Incompatible Firmware",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}