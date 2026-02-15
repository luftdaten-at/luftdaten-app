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

import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/app_settings.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/features/measurement/controllers/trip_controller.dart';
import 'package:luftdaten.at/features/measurement/models/measured_data.dart';
import 'package:luftdaten.at/model/ble_device.dart';
import 'package:luftdaten.at/shared/widgets/duration_widget.dart';
import 'package:luftdaten.at/shared/widgets/start_button.i18n.dart';
import 'package:luftdaten.at/shared/widgets/ui.dart';
import 'package:provider/provider.dart';

class StartButton extends StatefulWidget {
  const StartButton({super.key, required this.page, this.updateGPSCallback});

  final String page;
  final void Function()? updateGPSCallback;

  @override
  State<StatefulWidget> createState() => _StartButtonState();
}

class _StartButtonState extends State<StartButton> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TripController>(
      builder: (_, trips, __) => Consumer<DeviceManager>(builder: (context, devs, _) {
        if (devs.devices.where((e) => e.portable).isEmpty) {
          return const SizedBox(height: 0, width: 0);
        }
        return InkWell(
          onTap: () {},
          child: Container(
            width: 180,
            height: 54,
            decoration: BoxDecoration(
              color: trips.isOngoing ? Colors.white : Colors.green.shade200,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: trips.isOngoing
                ? Row(
                    children: [
                      Material(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: SizedBox(
                            width: 74,
                            child: Center(
                              child: DurationWidget(
                                initialTime: trips.currentTripStartedAt!,
                                builder: (_, duration) {
                                  String time = '';
                                  int totalSecs = duration.inSeconds;
                                  int hours = (totalSecs / 3600).floor();
                                  totalSecs -= hours * 3600;
                                  int minutes = (totalSecs / 60).floor();
                                  totalSecs -= minutes * 60;
                                  int seconds = totalSecs;
                                  if (hours > 0) time += '$hours:';
                                  time += minutes < 10 ? '0$minutes:' : '$minutes:';
                                  time += seconds < 10 ? '0$seconds' : '$seconds';
                                  return Text(
                                    time,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      VerticalDivider(
                        color: Colors.grey.shade400,
                        thickness: 1,
                        width: 1,
                      ),
                      Material(
                        color: Colors.red.shade100,
                        child: Tooltip(
                          message: 'Messung beenden'.i18n,
                          child: InkWell(
                            onTap: () => showLDDialog(
                              context,
                              title: 'Messungen beenden'.i18n,
                              icon: Icons.pause,
                              color: Colors.red,
                              text: 'Aktuelle Messung beenden?'.i18n,
                              actions: [
                                LDDialogAction.cancel(),
                                LDDialogAction(
                                  label: 'Beenden'.i18n,
                                  filled: true,
                                  onTap: () => toggleTrip(context),
                                ),
                              ],
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                              child: Icon(Icons.pause),
                            ),
                          ),
                        ),
                      ),
                      VerticalDivider(
                        color: Colors.grey.shade400,
                        thickness: 1,
                        width: 1,
                      ),
                      Material(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        child: PopupMenuButton<MobilityModes>(
                          tooltip: 'Transportmittel ändern'.i18n,
                          onSelected: (mode) => trips.mobilityMode = mode,
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<MobilityModes>(
                              value: MobilityModes.walking,
                              enabled: false,
                              child: Text(
                                'Transportmittel wählen'.i18n,
                                style: const TextStyle(
                                    color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                            PopupMenuItem<MobilityModes>(
                              value: MobilityModes.walking,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.directions_walk),
                                  const SizedBox(width: 8),
                                  Text('Zu Fuß'.i18n),
                                ],
                              ),
                            ),
                            PopupMenuItem<MobilityModes>(
                              value: MobilityModes.cycling,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.directions_bike),
                                  const SizedBox(width: 8),
                                  Text('Fahrrad/Roller'.i18n),
                                ],
                              ),
                            ),
                            PopupMenuItem<MobilityModes>(
                              value: MobilityModes.transit,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.tram),
                                  const SizedBox(width: 8),
                                  Text('Öffis'.i18n),
                                ],
                              ),
                            ),
                            PopupMenuItem<MobilityModes>(
                              value: MobilityModes.driving,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.directions_car),
                                  const SizedBox(width: 8),
                                  Text('Auto'.i18n),
                                ],
                              ),
                            ),
                          ],
                          position: PopupMenuPosition.over,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                            child: Icon(iconForMobilityMode(trips.mobilityMode)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Theme(
                    data: ThemeData.from(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
                    child: Builder(builder: (innerContext) {
                      return Material(
                        color: Theme.of(innerContext).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(15),
                        child: Tooltip(
                          message: 'Messung starten'.i18n,
                          child: InkWell(
                            onTap: () => toggleTrip(context),
                            child: const Center(child: Icon(Icons.play_arrow)),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        );
      }),
    );
  }

  void toggleTrip(BuildContext context) async {
    if (context.read<TripController>().isOngoing) {
      stopTrip();
      return;
    }
    BleDevice? device = await showDeviceSelectDialog(context, stopTrip, portable: true);
    if (device == null) return;

    if (context.mounted && context.read<TripController>().ongoingTrips.isNotEmpty) {
      showLDDialog(
        context,
        title: 'Route fortsetzen?'.i18n,
        icon: Icons.play_arrow,
        content: Text(
          'Es existiert bereits eine Route. Soll die alte Route fortgesetzt werden '
              'oder eine neue Route gestartet werden?'
              .i18n,
          textAlign: TextAlign.center,
        ),
        actions: [
          LDDialogAction(
            label: 'Neue Route'.i18n,
            filled: false,
            onTap: () {
              context.read<TripController>().clear();
              startTrip([device]);
            },
          ),
          LDDialogAction(
            label: 'Fortsetzen'.i18n,
            filled: true,
            onTap: () => startTrip([device]),
          ),
        ],
      );
    } else {
      startTrip([device]);
    }
  }

  void startTrip(List<BleDevice> devices) {
    logger.d('Starting trip');
    context.read<TripController>().startTrip(devices);
    if (AppSettings.I.followUserDuringMeasurements) {
      widget.updateGPSCallback?.call();
    }
  }

  void stopTrip() => context.read<TripController>().stopTrip();

  IconData iconForMobilityMode(MobilityModes mode) {
    switch (mode) {
      case MobilityModes.walking:
        return Icons.directions_walk;
      case MobilityModes.cycling:
        return Icons.directions_bike;
      case MobilityModes.driving:
        return Icons.directions_car;
      case MobilityModes.transit:
        return Icons.tram;
    }
  }
}
