import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Favoriten",
        "en": "Favorites",
      } +
      {
        "de": "Wähle eine Messstation auf der Luftkarte aus und tippe auf das Lesezeichen-Icon (rechts oben im Dialogfeld), um die Station zu Favoriten hinzuzufügen. Die Messdaten hinzugefügter Stationen können dann hier oder am Dashboard eingesehen werden.",
        "en": "Select a measuring station on the Map page and tap the bookmark icon (top right in the dialog box) to save the station to your favorites. The data of added stations can then be viewed here or on the your Dashboard page.",
      } +
      {
        "de": "Deine Favoriten:",
        "en": "Your favorites:",
      } +
      {
        "de": "Noch keine Favoriten hinzugefügt.",
        "en": "No favorites added yet.",
      } +
      {
        "de": "Station #%i",
        "en": "Station #%i",
      } +
      {
        "de": "Favorit löschen?",
        "en": "Delete favorite?",
      } +
      {
        "de": "Station #%i aus Favoriten löschen?",
        "en": "Delete station #%i from favorites?",
      } +
      {
        "de": "Abbrechen",
        "en": "Cancel",
      } +
      {
        "de": "Löschen",
        "en": "Delete",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}