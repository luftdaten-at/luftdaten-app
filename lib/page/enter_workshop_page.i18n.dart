import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("de") +
      {
        "de": 'Workshop beitreten',
        "en": 'Join Workshop',
      } +
      {
        "de": 'Beitritts-Code',
        "en": 'Access Code',
      } +
      {
        "de": 'Wie kann ich teilnehmen?',
        "en": 'How can I take part?',
      } +
      {
        "de": 'Wir organisieren regelmäßig Luftqualitäts-Workshops in ganz Österreich. '
            'Du würdest genre mitmachen? Die Termine der nächsten Workshops '
            'findest du auf unserer Webseite!',
        "en": 'We regularly organize air quality workshops throughout Austria. '
            'You would like to participate? You can find the dates of our upcoming workshops '
            'on our website!',
      } +
      {
        "de": 'Workshop %s',
        "en": 'Workshop %s',
      } +
      {
        "de": 'dd.MM.yyyy',
        "en": 'MMM dd, yyyy',
      } +
      {
        "de": 'HH:mm',
        "en": 'hh:mm a',
      } +
      {
        "de": 'dd.MM.yyyy, HH:mm',
        "en": 'MMM dd, yyyy, hh:mm a',
      } +
      {
        "de": 'Dieser Workshop liegt in der Vergangenheit.',
        "en": 'This workshop has already happened.',
      } +
      {
        "de": 'Zurück',
        "en": 'Back',
      } +
      {
        "de": 'Dieser Workshop hat noch nicht begonnen. '
            'Du kannst erst nach dem Beginn des Workshops beitreten.',
        "en": 'This workshop has not yet started. '
            'You can only join after the workshop has started.',
      } +
      {
        "de": 'Abbrechen',
        "en": 'Cancel',
      } +
      {
        "de": 'Workshop erfolgreich beigetreten.',
        "en": 'Successfully joined workshop.',
      } +
      {
        "de": 'Beitreten',
        "en": 'Join',
      } +
      {
        "de": 'Verbindungsfehler. Bitte überprüfe deine Internetverbindung.',
        "en": 'Connection error. Please check your internet connection.',
      } +
      {
        "de": 'Beitritts-Code ungültig.',
        "en": 'Invalid access code.',
      } +
      {
        "de": 'Ein Fehler ist aufgetreten.',
        "en": 'An error occurred.',
      } +
      {
        "de": '%s Uhr',
        "en": '%s',
      };

  String get i18n => localize(this, _t);

  String fill(List<Object> params) => localizeFill(this, params);
}
