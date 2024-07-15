import 'package:flutter/foundation.dart';

class AppLicenses {
  Map<String, PackageLicense> licenses = {};
  List<PackageLicense> licenseList = [];

  void init() async {
    List<LicenseEntry> entries = await LicenseRegistry.licenses.toList();
    for(LicenseEntry entry in entries.sublist(1)) {
      List<String> lines = entry.paragraphs.map((e) => e.text).toList(growable: false);
      for(String package in entry.packages) {
        if(licenses.containsKey(package)) {
          licenses[package]!.paragraphs.add(lines);
        } else {
          licenses[package] = PackageLicense(package, [lines]);
        }
      }
    }
    licenseList = licenses.values.toList()..sort((a, b) => a.packageName.compareTo(b.packageName));
  }
}

class PackageLicense {
  PackageLicense(this.packageName, this.paragraphs);

  final String packageName;
  List<List<String>> paragraphs;
}