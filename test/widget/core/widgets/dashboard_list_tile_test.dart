import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/core/widgets/dashboard_list_tile.dart';

void main() {
  testWidgets('DashboardListTile shows title, subtitle, and chevron', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardListTile(
            title: 'Test Title',
            subtitle: 'Test Subtitle',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Subtitle'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    final tileBox = tester.getSize(find.byType(DashboardListTile));
    expect(tileBox.height, greaterThanOrEqualTo(70));
  });

  testWidgets('DashboardListTile onTap fires', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardListTile(
            title: 'Tap Me',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap Me'));
    expect(tapped, isTrue);
  });

  testWidgets('DashboardListTile hides chevron when showChevron is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardListTile(
            title: 'No Chevron',
            onTap: () {},
            showChevron: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
