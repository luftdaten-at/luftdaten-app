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

class Date {
  const Date(this.day, this.month, this.year);

  final int day, month, year;

  @override
  int get hashCode => Object.hash(day, month, year);

  @override
  bool operator ==(Object other) {
    return other is Date && day == other.day && month == other.month && year == other.year;
  }
}

extension GetDate on DateTime {
  Date get date => Date(day, month, year);
}
