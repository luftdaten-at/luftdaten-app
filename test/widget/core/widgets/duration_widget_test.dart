import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/widgets/duration_widget.dart';

void main() {
  testWidgets('DurationWidget displays duration since initial', (WidgetTester tester) async {
    final initialTime = DateTime.now().subtract(const Duration(minutes: 5));

    await tester.pumpWidget(
      MaterialApp(
        home: DurationWidget(
          initialTime: initialTime,
          builder: (context, duration) => Text('${duration.inMinutes}'),
        ),
      ),
    );

    expect(find.byType(Text), findsOneWidget);
    // DurationWidget starts recursive tick() timers; dispose it before test end to avoid pending timer assertion
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 250));
  });
}
