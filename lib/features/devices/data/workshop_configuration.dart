import 'package:uuid/uuid.dart';

class WorkshopConfiguration {
  final String id, name, description, participantUid;
  /// In UTC
  final DateTime start, end;

  const WorkshopConfiguration({
    required this.id,
    required this.name,
    required this.description,
    required this.start,
    required this.end,
    required this.participantUid,
  });

  Map<String, dynamic> toJson() => {
    'name': id,
    'title': name,
    'description': description,
    'start_date': start.toIso8601String(),
    'end_date': end.toIso8601String(),
    'participant_uid': participantUid,
  };

  factory WorkshopConfiguration.fromJson(Map<String, dynamic> json) => WorkshopConfiguration(
    id: json['name'],
    name: json['title'],
    description: json['description'],
    start: DateTime.parse(json['start_date']).toUtc(),
    end: DateTime.parse(json['end_date']).toUtc(),
    participantUid: json['participant_uid'] ?? const Uuid().v1(),
  );
}
