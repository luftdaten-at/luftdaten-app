import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';

void main() {
  testWidgets('ChangeNotifierBuilder rebuilds when notifier changes',
      (WidgetTester tester) async {
    var counter = 0;
    final notifier = _TestNotifier();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierBuilder(
          notifier: notifier,
          builder: (context, n) => Text('${n.counter}'),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    counter = notifier.counter = 1;
    notifier.notifyListeners();
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}

class _TestNotifier extends ChangeNotifier {
  int counter = 0;
}
