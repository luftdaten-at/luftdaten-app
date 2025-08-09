import 'package:get_storage/get_storage.dart';
import '../../../constants/enums/enums.dart' as enums;

class PreferencesHandler {
  // This class stores user preferences for consistency between sessions
  // E.g., the map should resume from the user's most recent location, the PM settings should
  // persist, etc.

  final GetStorage _box = GetStorage('preferences');

  int _selectedPM = enums.Dimension.PM2_5;
  int get selectedPM => _selectedPM;
  set selectedPM(value) {
    _selectedPM = value;
    _box.write('mapShowPM', _selectedPM.toString());
  }

  void init() async {
    await GetStorage.init('preferences');
    _selectedPM = int.tryParse(_box.read('mapShowPM')) ?? enums.Dimension.PM2_5;
  }
}