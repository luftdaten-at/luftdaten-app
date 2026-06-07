import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:luftdaten.at/core/domain/dimensions.dart' as enums;
import 'package:luftdaten.at/features/map/presentation/widgets/map_collapsible_legend.dart';

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

  Widget buildLegend({required int dimensionId}) {
    return I18n(
      initialLocale: const Locale('de'),
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MapCollapsibleLegend(dimensionId: dimensionId),
          ),
        ),
      ),
    );
  }

  testWidgets('PM2.5 dimension renders collapsed strip with six colour segments',
      (tester) async {
    await tester.pumpWidget(buildLegend(dimensionId: enums.Dimension.PM2_5));

    expect(find.byKey(const Key('map-legend-color-segment')), findsNWidgets(6));
    expect(find.byKey(const Key('map-legend-expanded-content')), findsNothing);
  });

  testWidgets('tap expands and shows Eu-AQI title', (tester) async {
    await tester.pumpWidget(buildLegend(dimensionId: enums.Dimension.PM2_5));

    await tester.tap(find.byType(MapCollapsibleLegend));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('map-legend-expanded-content')), findsOneWidget);
    expect(find.textContaining('Eu‑Luftqualitätsindex'), findsOneWidget);
  });

  testWidgets('tap again collapses expanded legend', (tester) async {
    await tester.pumpWidget(buildLegend(dimensionId: enums.Dimension.PM2_5));

    await tester.tap(find.byType(MapCollapsibleLegend));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

    await tester.tap(find.byType(MapCollapsibleLegend));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(find.byKey(const Key('map-legend-expanded-content')), findsNothing);
  });

  testWidgets('unknown dimension renders nothing', (tester) async {
    await tester.pumpWidget(buildLegend(dimensionId: enums.Dimension.HUMIDITY));

    expect(find.byKey(const Key('map-legend-color-segment')), findsNothing);
    expect(find.byKey(const Key('map-legend-expanded-content')), findsNothing);
  });
}
