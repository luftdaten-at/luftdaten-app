import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/page/map_page.dart';

class PreferencesHandler {
  // This class stores user preferences for consistency between sessions
  // E.g., the map should resume from the user's most recent location, the PM settings should
  // persist, etc.

  final GetStorage _box = GetStorage('preferences');

  DisplayType _selectedPM = DisplayType.pm25;
  DisplayType get selectedPM => _selectedPM;
  set selectedPM(value) {
    _selectedPM = value;
    _box.write('mapShowPM', _selectedPM.label);
  }

  void init() async {
    await GetStorage.init('preferences');
    _selectedPM = DisplayType.values.where((e) => e.label == _box.read('mapShowPM')).firstOrNull ?? DisplayType.pm25;
  }
}