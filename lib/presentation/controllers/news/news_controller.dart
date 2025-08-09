import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';
import '../../../core/utils/extensions/string/string_extensions.dart';

import '../../../data/models/news/news_item.dart';

class NewsController extends ChangeNotifier {
  final GetStorage _box = GetStorage('news');
  late DateTime _lastRefresh;

  List<NewsItem> _items = [];

  List<NewsItem> get items => _items;

  void add(NewsItem item) {
    _items.insert(0, item);
    _box.write('items', _items.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  void remove(NewsItem item) {
    _items.remove(item);
    saveUpdates();
  }

  void clear() {
    _items.clear();
    _box.remove('items');
    notifyListeners();
  }

  NewsItem? itemForId(String uid) {
    return _items.firstWhere((element) => element.url == uid);
  }

  bool hasUnreadItems() {
    return _items.any((element) => !element.dismissed);
  }

  void archiveItem(NewsItem item) {
    item.dismissed = true;
    saveUpdates();
  }

  Future<void> init() async {
    await GetStorage.init('news');
    _items = (_box.read('items') ?? []).map<NewsItem>((e) => NewsItem.fromJson(e)).toList();
    _lastRefresh = DateTime.parse(_box.read('lastRefresh') ?? DateTime.now().toIso8601String());
    await _checkForNewItems();
  }

  Future<void> _checkForNewItems() async {
    Response response =
        await get(Uri.parse('https://luftdaten.at/wp-json/wp/v2/posts?categories=12'));
    if (response.statusCode == 200) {
      String content = response.body;
      List rawItems = json.decode(content);
      List<NewsItem> newsItems = rawItems
          .map((e) => NewsItem(
                timestamp: DateTime.parse(e['date_gmt']),
                uid: e['id'].toString(),
                title: (e['title']['rendered'] as String).stripHtml,
                description: (e['excerpt']['rendered'] as String).stripHtml,
                url: (e['link'] as String).replaceAll(r'\', ''),
              ))
          .toList();
      _items.addAll(newsItems.where((e) => e.timestamp.isAfter(_lastRefresh.toUtc())).toList());
      _lastRefresh = DateTime.now();
      _box.write('lastRefresh', _lastRefresh.toIso8601String());
      _box.write('items', _items.map((e) => e.toJson()).toList());
      notifyListeners();
    }
    // If fetch fails, fail silently and just try again on next app start
  }

  void refresh() {
    notifyListeners();
  }

  void saveUpdates() {
    _box.write('items', _items.map((e) => e.toJson()).toList());
    notifyListeners();
  }
}
