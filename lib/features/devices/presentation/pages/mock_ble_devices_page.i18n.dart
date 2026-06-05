import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": "Mock-BLE-Geräte",
        "en": "Mock BLE devices",
      } +
      {
        "de": "Mock-BLE aktiv",
        "en": "Mock BLE enabled",
      } +
      {
        "de":
            "Simuliert Verbindung und Messwerte ohne echtes Bluetooth (nur Debug-Build).",
        "en": "Simulates connection and readings without real Bluetooth (debug builds only).",
      } +
      {
        "de": "Air aRound hinzufügen",
        "en": "Add Air aRound",
      } +
      {
        "de": "Air Station hinzufügen",
        "en": "Add Air Station",
      } +
      {
        "de": "Beide Presets",
        "en": "Both presets",
      } +
      {
        "de": "Manuelle QR-Daten…",
        "en": "Manual QR data…",
      } +
      {
        "de": "Gespeicherte Mock-Geräte",
        "en": "Saved mock devices",
      } +
      {
        "de": "Keine Mock-Geräte. Füge ein Preset hinzu.",
        "en": "No mock devices. Add a preset.",
      } +
      {
        "de": "Mock-BLE ist deaktiviert. Schalte es oben ein.",
        "en": "Mock BLE is disabled. Enable it above.",
      } +
      {
        "de": "Mock-BLE-Geräte (Simulator)",
        "en": "Mock BLE devices (simulator)",
      } +
      {
        "de": "Mock-Gerät hinzufügen",
        "en": "Add mock device",
      } +
      {
        "de": "Mock-Geräte verwalten",
        "en": "Manage mock devices",
      };

  String get i18n => localize(this, _t);
}
