import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/widgets/progress.dart';

void main() {
  group('ProgressWaiter', () {
    testWidgets('renders with default size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressWaiter(),
          ),
        ),
      );

      expect(find.byType(ProgressWaiter), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('respects custom width and height', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressWaiter(width: 50, height: 80),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 50);
      expect(image.height, 80);
    });
  });
}
