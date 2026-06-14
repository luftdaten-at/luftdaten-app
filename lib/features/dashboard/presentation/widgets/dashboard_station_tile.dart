import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:luftdaten.at/features/dashboard/logic/favorites_manager.dart';
import 'package:luftdaten.at/features/map/logic/http_provider.dart';
import 'package:luftdaten.at/core/widgets/ui.dart';

import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/devices/presentation/widgets/ble_device_notices_banner.dart';
import 'package:luftdaten.at/features/map/presentation/pages/station_details_page.dart';
import 'package:luftdaten.at/features/map/presentation/widgets/station_display_name.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'dashboard_station_tile.i18n.dart';
import 'package:luftdaten.at/features/devices/data/air_station_config.dart';

class DashboardStationTile extends StatefulWidget {
  const DashboardStationTile({super.key, this.device, this.favorite, this.dragController})
      : assert((device ?? favorite) != null,
            'DashboardStationTile requires one of device or id to be specified.');

  /// For Air Stations connected directly via Luftdaten.at servers
  final BleDevice? device;

  /// For devices loaded from sensor.community and stored as favorites
  final Favorite? favorite;

  final DragController? dragController;

  @override
  State<DashboardStationTile> createState() => _DashboardStationTileState();
}

class _DashboardStationTileState extends State<DashboardStationTile> {
  late SingleStationHttpProvider provider;
  late String deviceId;

  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    /**
     * when device != null -> it is a connected ble device and device id can be retrieved via
     * AirStationConfigManager
     * Otherwise favorite != null and device id can be retrieved from there
     */
    
    String deviceId = "";
    if(widget.device != null){
      // TODO find better Method of getting the Device ID if AirStationConfig is null
      String backupDeviceId = '${widget.device!.bleName.split("-")[1]}AAA';
      deviceId = AirStationConfigManager.getConfig(widget.device!.bleName)?.deviceId ?? backupDeviceId;
    }else{
      deviceId = widget.favorite!.id;
    }

    this.deviceId = deviceId;
    provider = SingleStationHttpProvider(
      deviceId,
      currentOnly: true,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ChangeNotifierBuilder(
          notifier: provider,
          builder: (context, provider) {
            return NullableChangeNotifierBuilder(
                notifier: widget.dragController,
                builder: (context, dragController) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 70,
                  decoration: BoxDecoration(
                    color: _getColor(),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: dragController != null
                        ? [BoxShadow(color: Colors.black, blurRadius: dragController.isDragging ? 6 : 0)]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StationDetailsPage(
                              id: widget.favorite?.id,
                              device: widget.device,
                              httpProvider: provider,
                            ),
                          ),
                        );
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
                                  StationDisplayName(
                                    stationId: deviceId,
                                    localDevice: widget.device,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (widget.favorite?.id != null &&
                                      widget.favorite!.locationString !=
                                          null)
                                    Text(widget.favorite!
                                        .locationString!),
                                ],
                              ),
                            ),
                            if (widget.device != null)
                              ChangeNotifierBuilder(
                                notifier: widget.device!,
                                builder: (_, dev) =>
                                    BleDeviceNoticesBanner(device: dev, compact: true),
                              ),
                            SizedBox(
                                width: 50,
                                child: Align(alignment: Alignment.centerRight, child: _buildStatus())),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => StationDetailsPage(
                                    id: widget.favorite?.id,
                                    device: widget.device,
                                    httpProvider: provider,
                                  ),
                                ));
                              },
                              tooltip: 'Details'.i18n,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            );
          }),
    );
  }

  Widget _buildStatus() {
    if (!provider.currentReady) {
      return SpinKitDualRing(
        color: Theme.of(context).primaryColor,
        size: 20,
        lineWidth: 2,
      );
    }
    if (provider.currentError) {
      return IconButton(
        onPressed: () {
          showLDDialog(
            context,
            title: 'Ladefehler'.i18n,
            icon: Icons.error_outline,
            text: 'Daten konnten nicht geladen werden. Überprüfe deine Internetverbindung.'.i18n,
          );
        },
        icon: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.primary),
        tooltip: 'Ladefehler'.i18n,
      );
    }
    if (provider.currentReading?.pm25 == null) {
      return IconButton(
        onPressed: () {
          showLDDialog(
            context,
            title: 'Keine Daten'.i18n,
            icon: Icons.error_outline,
            text:
                'Von dieser Station sind keine Daten verfügbar. Wenn du die Station zum ersten Mal verwendest, kann es einige Minuten dauern, bis Daten eintreffen.'
                    .i18n,
            actions: [
              LDDialogAction(
                  label: 'Neu suchen'.i18n,
                  filled: false,
                  onTap: () {
                    provider.refetch();
                  }),
              LDDialogAction(label: 'Schließen'.i18n, filled: true),
            ],
          );
        },
        tooltip: 'Keine Daten'.i18n,
        icon: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.primary),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('PM2.5', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(provider.currentReading!.pm25!.toStringAsFixed(1)),
      ],
    );
  }

  Color _getColor() {
    final pm25 = provider.currentReading?.pm25;
    if (provider.currentReady && !provider.currentError && pm25 != null) {
      if (pm25 < 5) return Colors.green.shade50;
      if (pm25 < 15) return Colors.orange.shade50;
      return Colors.red.shade50;
    }
    return Theme.of(context).colorScheme.primaryContainer;
  }
}

class DragController extends ChangeNotifier {
  bool _isDragging = false;

  bool get isDragging => _isDragging;

  set isDragging(bool value) {
    if (_isDragging != value) {
      _isDragging = value;
      notifyListeners();
    }
  }
}