import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Messungen importieren?",
        "en": "Import measurements?",
      } +
      {
        "de":
            "Der Import liest die offline gespeicherten Messungen deines Air Badge über Bluetooth (%s Datensätze).\n\n"
                "Messmodus muss beendet sein. Übertragung erfolgt unverschlüsselt wie bei BLE üblich — nutze wenn "
                "möglich keine öffentliche Umgebung.\n\n"
                "Danach werden die Messungen als Messreihe in Messwerte geladen.",
        "en":
            "This import reads the offline measurements from your Air Badge over Bluetooth (%s records).\n\n"
                "Measurement mode must be stopped. Transfer is unencrypted as usual for BLE — avoid public "
                "environments when possible.\n\n"
                "The measurements are then loaded as a measurement series in Messwerte.",
      } +
      {
        "de": "Messungen werden über Bluetooth geladen…",
        "en": "Loading measurements over Bluetooth…",
      } +
      {
        "de": "Import während einer laufenden Messung nicht möglich.",
        "en": "Import is not possible during an ongoing measurement trip.",
      } +
      {
        "de": "%s Messpunkte importiert — in Messwerte anzeigen.",
        "en": "%s measurement points imported — view in Messwerte.",
      } +
      {
        "de": "Import fehlgeschlagen: Messwerte nicht verfügbar.",
        "en": "Import failed: Messwerte not available.",
      } +
      {
        "de": "Messungen auf dem Badge löschen?",
        "en": "Delete measurements on badge?",
      } +
      {
        "de":
            "Die Messungen wurden in Messwerte geladen. Sollen sie auch vom Badge gelöscht werden?",
        "en":
            "The measurements were loaded into Messwerte. Should they also be deleted from the badge?",
      } +
      {
        "de": "Behalten",
        "en": "Keep",
      } +
      {
        "de": "Löschen",
        "en": "Delete",
      } +
      {
        "de": "Messungen auf dem Badge gelöscht.",
        "en": "Measurements deleted on badge.",
      } +
      {
        "de": "Messungen konnten auf dem Badge nicht gelöscht werden.",
        "en": "Could not delete measurements on badge.",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
