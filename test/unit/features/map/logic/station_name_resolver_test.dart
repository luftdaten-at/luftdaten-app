import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/features/map/logic/station_name_resolver.dart';

void main() {
  group('StationNameResolver.datahubLookupKey', () {
    test('strips SC suffix for numeric map station ids', () {
      expect(StationNameResolver.datahubLookupKey('1SC'), '1');
      expect(StationNameResolver.datahubLookupKey('278SC'), '278');
    });

    test('returns trimmed id when not numeric SC format', () {
      expect(StationNameResolver.datahubLookupKey('D83BDA43D465AAA'), 'D83BDA43D465AAA');
      expect(StationNameResolver.datahubLookupKey(' 42SC '), '42');
    });
  });

  group('StationNameResolver.displayLabel', () {
    test('uses Station {n}SC for numeric SC station ids', () {
      final resolver = StationNameResolver();
      resolver.putCachedNameForTest('1SC', 'Station 1SC');

      expect(
        resolver.displayLabel(
          stationId: '1SC',
          localDevice: null,
          fallback: (id) => 'Station #$id',
        ),
        'Station 1SC',
      );

      expect(
        resolver.displayLabel(
          stationId: '99SC',
          localDevice: null,
          fallback: (id) => 'Station #$id',
        ),
        'Station 99SC',
      );
    });
  });

  group('StationNameResolver.formatNameForStationId', () {
    test('appends SC to API name for numeric SC ids', () {
      expect(StationNameResolver.formatNameForStationId('1SC', 'Station 1'), 'Station 1SC');
      expect(StationNameResolver.formatNameForStationId('278SC', 'Station 278'), 'Station 278SC');
    });

    test('keeps API name for other ids', () {
      expect(
        StationNameResolver.formatNameForStationId('D83BDA43D465AAA', 'Station 1'),
        'Station 1',
      );
    });
  });
}
