import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/app_licenses.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/shared/utils/list_extensions.dart';

import 'licenses_page.i18n.dart';

class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  static const String route = 'licenses';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Package-Lizenzen'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: getIt<AppLicenses>()
                .licenseList
                .map((e) => _buildLicenseTile(context, e))
                .toList()
                .spaceWith(const Divider(height: 1)),
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseTile(BuildContext context, PackageLicense packageLicense) {
    return ListTile(
      title: Text(
        packageLicense.packageName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(packageLicense.packageName, style: const TextStyle(color: Colors.white)),
              backgroundColor: Theme.of(context).primaryColor,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 40),
                child: Column(
                  children: [Text(packageLicense.paragraphs.map((e) => e.join('\n\n')).join('\n\n---------------\n\n'))],
                ),
              ),
            ),
          );
        }));
      },
    );
  }
}
