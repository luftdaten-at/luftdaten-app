import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/widgets/code_field.dart';

void main() {
  group('CodeField', () {
    testWidgets('renders and accepts alphanumeric input', (WidgetTester tester) async {
      String? changedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeField(
              onChanged: (val) => changedValue = val,
            ),
          ),
        ),
      );

      expect(find.byType(CodeField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ABC123');
      await tester.pump();

      expect(changedValue, 'ABC123');
    });

    testWidgets('limits input to 6 characters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeField(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ABCDEF123');
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      final controller = tester.widget<TextField>(find.byType(TextField)).controller;
      expect(controller?.text.length, lessThanOrEqualTo(6));
    });
  });
}
