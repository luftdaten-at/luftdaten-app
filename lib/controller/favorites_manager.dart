import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/main.dart';

class FavoritesManager extends ChangeNotifier {
  GetStorage box = GetStorage('favorites');

  List<Favorite> _favorites = [];

  Future<void> init() async {
    await GetStorage.init('favorites');
    List<dynamic> favRaw = box.read('fav') ?? [];
    for (dynamic e in favRaw) {
      Map<dynamic, dynamic> json = (e as Map).cast<String, dynamic>();
      Favorite favorite = Favorite.fromJson(json);
      _favorites.add(favorite);
    }
    notifyListeners();
  }

  void add(Favorite favorite) {
    _favorites.add(favorite);
    save();
    notifyListeners();
  }

  bool hasId(String id) {
    return _favorites.any((e) => e.id == id);
  }

  void removeId(String id) {
    _favorites.removeWhere((e) => e.id == id);
    save();
    notifyListeners();
  }

  void addByIdAndLocation(String id, LatLng latLng) {
    Favorite favorite = Favorite(id: id, latLng: latLng);
    _favorites.add(favorite);
    save();
    notifyListeners();
  }

  void remove(Favorite favorite) {
    _favorites.remove(favorite);
    save();
    notifyListeners();
  }

  void reset() {
    _favorites = [];
    save();
    notifyListeners();
  }

  void save() {
    box.write('fav', _favorites.map((e) => e.toJson()).toList());
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  List<Favorite> get favorites => _favorites;
}

class Favorite {
  final String id;
  final LatLng latLng;
  String? _locationString;
  String? _name;

  String? get locationString => _locationString;

  set locationString(String? s) {
    _locationString = s;
    getIt<FavoritesManager>().save();
  }

  String? get name => _name;

  set name(String? s) {
    _name = s;
    getIt<FavoritesManager>().save();
  }

  Favorite({required this.id, required this.latLng, String? locationString, String? name})
      : _locationString = locationString,
        _name = name;

  Map<dynamic, dynamic> toJson() => {
        'id': id,
        'latLng': latLng.toJson(),
        if (locationString != null) 'locationString': locationString,
        if (name != null) 'name': name,
      };

  factory Favorite.fromJson(Map<dynamic, dynamic> json) => Favorite(
        id: json['id'],
        latLng: LatLng.fromJson(json['latLng']),
        locationString: json['locationString'],
        name: json['name'],
      );
}
