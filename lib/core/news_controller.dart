/*
   Copyright (C) 2023 Thomas Ogrisegg for luftdaten.at

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';
import 'package:luftdaten.at/model/news_item.dart';
import 'package:luftdaten.at/shared/utils/string_extensions.dart';

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
    _items = (_box.read('items') ?? [])
        .map<NewsItem>((e) => NewsItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _lastRefresh =
        DateTime.parse(_box.read('lastRefresh') ?? DateTime.now().toIso8601String());
    await _checkForNewItems();
  }

  /// Expected JSON format from API (WordPress REST API posts):
  /// [
  ///   {
  ///     "date_gmt": "2024-01-15T10:00:00",
  ///     "id": 12345,
  ///     "title": { "rendered": "<p>Title text</p>" },
  ///     "excerpt": { "rendered": "<p>Excerpt text</p>" },
  ///     "link": "https://luftdaten.at/news/..."
  ///   },
  ///   ...
  /// ]
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
      _items.addAll(
          newsItems.where((e) => e.timestamp.isAfter(_lastRefresh.toUtc())).toList());
      _lastRefresh = DateTime.now();
      _box.write('lastRefresh', _lastRefresh.toIso8601String());
      _box.write('items', _items.map((e) => e.toJson()).toList());
      notifyListeners();
    }
  }

  void refresh() {
    notifyListeners();
  }

  void saveUpdates() {
    _box.write('items', _items.map((e) => e.toJson()).toList());
    notifyListeners();
  }
}
