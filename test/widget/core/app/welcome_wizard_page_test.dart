import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:luftdaten.at/core/app/presentation/welcome_wizard_page.dart';

void main() {
  setUpAll(() {
    Translations.missingKeyCallback = (_, __) {};
    Translations.missingTranslationCallback = ({
      required key,
      required locale,
      required translations,
      required supportedLocales,
    }) =>
        false;
  });

  Widget buildTestApp({Locale? locale}) {
    return I18n(
      initialLocale: locale ?? const Locale('de'),
      child: MaterialApp(
        initialRoute: '/wizard',
        routes: {
          '/': (context) => const Scaffold(body: Text('Home')),
          '/wizard': (context) => const WelcomeWizardPage(),
        },
      ),
    );
  }

  testWidgets('landing page shows welcome title', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('Willkommen'), findsOneWidget);
  });

  testWidgets('landing page shows purpose question', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(
      find.text(
        'Für welchen Zweck möchtest Du die Luftdaten.at-App verwenden? '
        'Du kannst die App später auch für weitere Zwecke konfigurieren.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('landing page shows three option tiles', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('Die Luftqualität in meiner Umgebung auf der Luftkarte einsehen.'), findsOneWidget);
    expect(find.text('Mit einem Tragbares Messgerät (z. B. Air aRound) messen.'), findsOneWidget);
    expect(find.text('Ein stationäres Messgerät (z. B. Air Station) konfigurieren.'), findsOneWidget);
  });

  testWidgets('tapping map option navigates to home', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('Die Luftqualität in meiner Umgebung auf der Luftkarte einsehen.'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('landing has correct key for testing', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.byKey(const Key('welcome-wizard-landing')), findsOneWidget);
  });

  testWidgets('English locale shows translated strings', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp(locale: const Locale('en')));

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('View air quality in my area on the air quality map.'), findsOneWidget);
  });

  testWidgets('stationary device tile shows configure option', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(
      find.text('Ein stationäres Messgerät (z. B. Air Station) konfigurieren.'),
      findsOneWidget,
    );
  });
}
