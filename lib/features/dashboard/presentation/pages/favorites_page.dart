import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:luftdaten.at/features/dashboard/logic/favorites_manager.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/dashboard/presentation/pages/station_details_page.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';

import 'favorites_page.i18n.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  static const String route = 'favorites';

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    updateLocationStrings();
    super.initState();
  }

  void updateLocationStrings() async {
    FavoritesManager favoritesManager = getIt<FavoritesManager>();
    for (Favorite favorite in favoritesManager.favorites) {
      if (favorite.locationString == null) {
        await setLocaleIdentifier(locale ?? 'de');
        List<Placemark> placemarks = await placemarkFromCoordinates(
          favorite.latLng.latitude,
          favorite.latLng.longitude,
        );
        logger.d('Reverse geocoding result:');
        for (Placemark placemark in placemarks) {
          logger.d(placemark.toString());
        }
        if (placemarks.firstOrNull != null) {
          // TODO verify that this formatting also works on Android
          Placemark placemark = placemarks.first;
          if (placemark.thoroughfare != null &&
              placemark.postalCode != null &&
              placemark.administrativeArea != null) {
            String locationString =
                '${placemark.thoroughfare}, ${placemark.postalCode} ${placemark.administrativeArea}';
            favorite.locationString = locationString;
            favoritesManager.notifyListeners();
            logger.d('Formatted location: $locationString');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    FavoritesManager favoritesManager = getIt<FavoritesManager>();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Favoriten'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ChangeNotifierBuilder(
              notifier: favoritesManager,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Wähle eine Messstation auf der Luftkarte aus und tippe auf das Lesezeichen-Icon (rechts oben im Dialogfeld), um die Station zu Favoriten hinzuzufügen. Die Messdaten hinzugefügter Stationen können dann hier oder am Dashboard eingesehen werden.'
                            .i18n),
                    const SizedBox(height: 8),
                    Text(
                      'Deine Favoriten:'.i18n,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ...favoritesManager.favorites.map((e) => _buildFavoriteTile(e)),
                    if (favoritesManager.favorites.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Noch keine Favoriten hinzugefügt.'.i18n,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                );
              }),
        ),
      ),
    );
  }

  Widget _buildFavoriteTile(Favorite favorite) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              // TODO open station details screen for this station
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StationDetailsPage(id: favorite.id),
              ));
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Station #%s'.i18n.fill([favorite.id]),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (favorite.locationString != null) Text(favorite.locationString!)
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showLDDialog(
                        context,
                        title: 'Favorit löschen?',
                        icon: Icons.delete,
                        color: Colors.red,
                        text: 'Station #%s aus Favoriten löschen?'.i18n.fill([favorite.id]),
                        actions: [
                          LDDialogAction(label: 'Abbrechen'.i18n, filled: false),
                          LDDialogAction(
                            label: 'Löschen'.i18n,
                            filled: true,
                            onTap: () {
                              getIt<FavoritesManager>().remove(favorite);
                            },
                          ),
                        ],
                      );
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
