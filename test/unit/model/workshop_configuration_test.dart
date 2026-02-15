import 'package:flutter_test/flutter_test.dart';
import 'package:luftdaten.at/model/workshop_configuration.dart';

void main() {
  group('WorkshopConfiguration', () {
    test('fromJson and toJson roundtrip', () {
      final config = WorkshopConfiguration(
        id: 'ws-1',
        name: 'Workshop 1',
        description: 'Desc',
        start: DateTime.utc(2024, 3, 15),
        end: DateTime.utc(2024, 3, 20),
        participantUid: 'participant-123',
      );
      final json = config.toJson();
      expect(json['name'], 'ws-1');
      expect(json['title'], 'Workshop 1');
      expect(json['participant_uid'], 'participant-123');
    });

    test('fromJson parses dates', () {
      final config = WorkshopConfiguration.fromJson({
        'name': 'ws-1',
        'title': 'Title',
        'description': 'Desc',
        'start_date': '2024-03-15T00:00:00.000Z',
        'end_date': '2024-03-20T00:00:00.000Z',
        'participant_uid': 'uid-1',
      });
      expect(config.id, 'ws-1');
      expect(config.name, 'Title');
      expect(config.start.isUtc, isTrue);
      expect(config.end.year, 2024);
    });
  });
}
