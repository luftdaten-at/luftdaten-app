import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../presentation/controllers/favorites/favorites_manager.dart';
import '../../../core/services/network/http/http_provider.dart';
import '../../../main.dart';
import '../../../presentation/widgets/common/ui/ui.dart';

import '../../../data/models/ble/ble_device.dart';
import '../../../presentation/pages/station/station_details_page/station_details_page.dart';
import '../../../presentation/widgets/common/change_notifier/change_notifier_builder.dart';
import 'dashboard_station_tile.i18n.dart';
import '../../../data/models/air_station/air_station_config.dart';

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

  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    /**
     * when device != null -> it is a connected ble device and device id can be retrieved via
     * AirStationConfigManager
     * Otherwise favorite != null and device id can be retrieved from there
     */
    
    String device_id = "";
    if(widget.device != null){
      // TODO find better Method of getting the Device ID if AirStationConfig is null
      String backupDeviceId = '${widget.device!.bleName.split("-")[1]}AAA';
      device_id = AirStationConfigManager.getConfig(widget.device!.bleName)?.deviceId ?? backupDeviceId;
    }else{
      device_id = widget.favorite!.id;
    }

    provider = SingleStationHttpProvider(
      device_id,
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
                                  Text(
                                    widget.device != null
                                        ? 'Air Station'.i18n
                                        : widget.favorite!.name ??
                                            'Station #%i'.i18n.fill([widget.favorite!.id]),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (widget.device != null) Text(widget.device!.displayName),
                                  if (widget.favorite?.id != null &&
                                      widget.favorite!.locationString !=
                                          null)
                                    Text(widget.favorite!
                                        .locationString!),
                                ],
                              ),
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
    if (provider.finished) {
      if (provider.error) {
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
      } else {
        if (provider.items.firstOrNull?.isEmpty ?? true) {
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
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('PM2.5', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(provider.items[0].last.pm25?.toStringAsFixed(1) ?? "nan"),
            ],
          );
        }
      }
    }
    return SpinKitDualRing(
      color: Theme.of(context).primaryColor,
      size: 20,
      lineWidth: 2,
    );
  }

  Color _getColor() {
    if (provider.finished && !provider.error) {
      if (provider.items[0].lastOrNull?.pm25 != null) {
        double pm25 = provider.items[0].last.pm25 ?? 0;
        if (pm25 < 5) return Colors.green.shade50;
        if (pm25 < 15) return Colors.orange.shade50;
        return Colors.red.shade50;
      }
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