import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Messprotokoll importieren (BLE)",
        "en": "Import measurement log (BLE)",
      } +
      {
        "de": "Messprotokoll importieren?",
        "en": "Import measurement log?",
      } +
      {
        "de":
            "Der Import liest das offline gespeicherte Messprotokoll deines Air Badge über Bluetooth (%s Datensätze).\n\n"
                "Messmodus muss beendet sein. Übertragung erfolgt unverschlüsselt wie bei BLE üblich — nutze wenn "
                "möglich keine öffentliche Umgebung.\n\n"
                "Danach werden die Rohzeilen lokal gespeichert und nacheinander an den Luftdaten-Datahub gesendet. "
                "Bei vollständigem Erfolg wird das Protokoll auf dem Badge gelöscht.",
        "en":
            "This import reads the offline measurement log from your Air Badge over Bluetooth (%s records).\n\n"
                "Measurement mode must be stopped. Transfer is unencrypted as usual for BLE — avoid public "
                "environments when possible.\n\n"
                "Raw lines are saved locally and sent to the Luftdaten Datahub one by one. "
                "On full success the log on the badge is erased.",
      } +
      {
        "de": "Messprotokoll wird über Bluetooth geladen…",
        "en": "Loading measurement log over Bluetooth…",
      } +
      {
        "de": "Import während einer laufenden Messung nicht möglich.",
        "en": "Import is not possible during an ongoing measurement trip.",
      } +
      {
        "de": "Messmodus aktiv — Aufzeichnung läuft auf dem Badge.",
        "en": "Measurement mode active — recording on the badge.",
      } +
      {
        "de": "Messprotokoll auf dem Badge gelöscht.",
        "en": "Measurement log erased on badge.",
      } +
      {
        "de": "Messprotokoll konnte auf dem Badge nicht gelöscht werden.",
        "en": "Could not erase measurement log on badge.",
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
