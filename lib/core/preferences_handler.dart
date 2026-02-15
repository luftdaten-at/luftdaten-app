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

import 'package:get_storage/get_storage.dart';
import 'package:luftdaten.at/shared/domain/dimensions.dart' as enums;

class PreferencesHandler {
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
