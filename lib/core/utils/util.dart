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

import 'dart:typed_data';

class Util {
  static Uint8List toByteArray(dynamic input) {
    if (input is int) {
      final byteData = ByteData(4);
      byteData.setInt32(0, input, Endian.big);
      return byteData.buffer.asUint8List();
    } else if (input is double) {
      final byteData = ByteData(8);
      byteData.setFloat64(0, input, Endian.big);
      return byteData.buffer.asUint8List();
    } else if (input is String) {
      return Uint8List.fromList(input.codeUnits);
    } else {
      throw ArgumentError('Input must be an int, double, or String.');
    }
  }
}
