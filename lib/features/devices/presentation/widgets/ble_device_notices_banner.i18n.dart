import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText('de') +
      {
        'de': 'Konfiguration unvollständig',
        'en': 'Configuration incomplete',
      } +
      {
        'de': 'Kein Sensor verbunden',
        'en': 'No sensor connected',
      } +
      {
        'de': 'WLAN-Verbindung fehlgeschlagen',
        'en': 'Wi-Fi connection failed',
      } +
      {
        'de': 'WLAN: Zugangsdaten nicht konfiguriert',
        'en': 'Wi-Fi: credentials not configured',
      } +
      {
        'de': 'WLAN: SSID nicht gefunden',
        'en': 'Wi-Fi: SSID not found in scan',
      } +
      {
        'de': 'WLAN: Verbindung fehlgeschlagen (Passwort, Timeout, …)',
        'en': 'Wi-Fi: connection failed (password, timeout, …)',
      } +
      {
        'de': 'Gerätestatus',
        'en': 'Device status',
      } +
      {
        'de': 'Gerät: %s',
        'en': 'Device: %s',
      };

  String get i18n => localize(this, _t);
}
