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

import 'package:flutter/foundation.dart';

class AppLicenses {
  Map<String, PackageLicense> licenses = {};
  List<PackageLicense> licenseList = [];

  void init() async {
    List<LicenseEntry> entries = await LicenseRegistry.licenses.toList();
    for (LicenseEntry entry in entries.sublist(1)) {
      List<String> lines = entry.paragraphs.map((e) => e.text).toList(growable: false);
      for (String package in entry.packages) {
        if (licenses.containsKey(package)) {
          licenses[package]!.paragraphs.add(lines);
        } else {
          licenses[package] = PackageLicense(package, [lines]);
        }
      }
    }
    licenseList = licenses.values.toList()
      ..sort((a, b) => a.packageName.compareTo(b.packageName));
  }
}

class PackageLicense {
  PackageLicense(this.packageName, this.paragraphs);

  final String packageName;
  List<List<String>> paragraphs;
}
