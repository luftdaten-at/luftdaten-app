class NewsItem {
  DateTime timestamp;
  String uid;
  String title;
  String description;
  String? url;
  bool dismissed;

  NewsItem(
      {required this.timestamp,
      required this.uid,
      required this.title,
      required this.description,
      this.url,
      this.dismissed = false});

  factory NewsItem.fromJson(Map<dynamic, dynamic> json) => NewsItem(
        timestamp: DateTime.parse(json['timestamp']),
        uid: json['uid'],
        title: json['title'],
        description: json['description'],
        url: json['url'],
        dismissed: json['dismissed'] ?? false,
      );

  Map<dynamic, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'uid': uid,
        'title': title,
        'description': description,
        if (url != null) 'url': url,
        'dismissed': dismissed
      };
}
