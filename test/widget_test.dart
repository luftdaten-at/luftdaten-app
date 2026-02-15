import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: MaterialApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Luftdaten.at')),
      ),
    );
    expect(find.text('Luftdaten.at'), findsOneWidget);
  });
}
