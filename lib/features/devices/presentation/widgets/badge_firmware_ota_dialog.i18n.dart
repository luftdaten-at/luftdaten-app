import 'package:i18n_extension/i18n_extension.dart';

extension BadgeFirmwareOtaLocalization on String {
  static final _t = Translations.byText('de') +
      {
        'de': 'Bluetooth zuerst verbinden.',
        'en': 'Connect Bluetooth first.',
      } +
      {
        'de': 'Firmware-Update während einer laufenden Messung nicht möglich.',
        'en': 'Firmware update is not available during an active measurement.',
      } +
      {
        'de': 'Firmware aktualisieren',
        'en': 'Update firmware',
      } +
      {
        'de': 'Abbrechen',
        'en': 'Cancel',
      } +
      {
        'de': 'Datei wählen',
        'en': 'Choose file',
      } +
      {
        'de': 'Von GitHub laden',
        'en': 'Download from GitHub',
      } +
      {
        'de': 'Die gewählte Version ist nicht neuer als die installierte.',
        'en': 'The selected version is not newer than the installed one.',
      } +
      {
        'de': 'Update starten?',
        'en': 'Start update?',
      } +
      {
        'de': 'Update starten',
        'en': 'Start update',
      } +
      {
        'de': 'Release wird geladen…',
        'en': 'Loading release…',
      } +
      {
        'de': 'Kein Firmware-Release verfügbar.',
        'en': 'No firmware release available.',
      } +
      {
        'de': 'Kein neueres Release auf GitHub (%s).',
        'en': 'No newer release on GitHub (%s).',
      } +
      {
        'de': 'Firmware-Datei konnte nicht gelesen werden.',
        'en': 'Could not read firmware file.',
      } +
      {
        'de': 'Firmware-Version',
        'en': 'Firmware version',
      } +
      {
        'de': 'Versionsnummer der gewählten Datei eingeben.',
        'en': 'Enter the version number of the selected file.',
      } +
      {
        'de': 'Major',
        'en': 'Major',
      } +
      {
        'de': 'Minor',
        'en': 'Minor',
      } +
      {
        'de': 'Patch',
        'en': 'Patch',
      } +
      {
        'de': 'OK',
        'en': 'OK',
      } +
      {
        'de': 'Firmware wird übertragen…',
        'en': 'Transferring firmware…',
      } +
      {
        'de': 'Firmware aktualisiert (%s).',
        'en': 'Firmware updated (%s).',
      } +
      {
        'de': 'Firmware-Update abgebrochen.',
        'en': 'Firmware update cancelled.',
      } +
      {
        'de': 'Firmware-Update fehlgeschlagen.',
        'en': 'Firmware update failed.',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
