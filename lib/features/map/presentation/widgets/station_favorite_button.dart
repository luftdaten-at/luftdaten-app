import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/core/config/env.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:luftdaten.at/features/dashboard/logic/favorites_manager.dart';

import 'station_favorite_button.i18n.dart';

class StationFavoriteButton extends StatelessWidget {
  const StationFavoriteButton({
    super.key,
    required this.deviceId,
    required this.resolveLocation,
    this.iconColor,
  });

  final String deviceId;
  final Future<LatLng?> Function() resolveLocation;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final favoritesManager = getIt<FavoritesManager>();
    return ChangeNotifierBuilder(
      notifier: favoritesManager,
      builder: (context, manager) {
        final selected = manager.hasId(deviceId);
        return IconButton(
          tooltip: selected ? 'Aus Favoriten entfernen'.i18n : 'Zu Favoriten hinzufügen'.i18n,
          onPressed: () => _onPressed(context, manager, selected),
          icon: Icon(
            selected ? Icons.bookmark_added : Icons.bookmark_add_outlined,
            color: iconColor,
          ),
        );
      },
    );
  }

  Future<void> _onPressed(
    BuildContext context,
    FavoritesManager manager,
    bool selected,
  ) async {
    if (selected) {
      manager.removeId(deviceId);
      return;
    }

    final latLng = await resolveLocation();
    if (!context.mounted) return;
    if (latLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Standort konnte nicht ermittelt werden'.i18n)),
      );
      return;
    }

    final favorite = Favorite(id: deviceId, latLng: latLng);
    manager.add(favorite);

    await setLocaleIdentifier(locale ?? 'de');
    final placemarks = await placemarkFromCoordinates(
      latLng.latitude,
      latLng.longitude,
    );
    logger.d('Reverse geocoding result:');
    for (final placemark in placemarks) {
      logger.d(placemark.toString());
    }
    final placemark = placemarks.firstOrNull;
    if (placemark != null &&
        placemark.thoroughfare != null &&
        placemark.postalCode != null &&
        placemark.administrativeArea != null) {
      final locationString =
          '${placemark.thoroughfare}, ${placemark.postalCode} ${placemark.administrativeArea}';
      favorite.locationString = locationString;
      logger.d('Formatted location: $locationString');
    }
  }
}
