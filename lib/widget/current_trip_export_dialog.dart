import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/controller/trip_controller.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/model/ble_device.dart';
import 'package:luftdaten.at/model/chip_id.dart';
import 'package:luftdaten.at/util/list_extensions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/trip.dart';
import 'current_trip_export_dialog.i18n.dart';

class CurrentTripExportDialog extends StatefulWidget {
  const CurrentTripExportDialog({super.key, this.trips});

  final List<Trip>? trips;

  @override
  State<StatefulWidget> createState() => _CurrentTripExportDialog();
}

class _CurrentTripExportDialog extends State<CurrentTripExportDialog> {
  Map<Trip, bool> selectedTrips = {};
  bool exportAsCsv = false;

  @override
  void initState() {
    if(widget.trips != null) {
      for(Trip trip in widget.trips!) {
        selectedTrips[trip] = true;
      }
    } else {
      TripController tripController = getIt<TripController>();
      if (tripController.ongoingTrips.isNotEmpty) {
        selectedTrips = tripController.ongoingTrips.map((key, value) => MapEntry(value, true));
      } else {
        selectedTrips = {};
        for(Trip trip in tripController.loadedTrips) {
          selectedTrips[trip] = true;
        }
      }
      selectedTrips.removeWhere((key, value) => key.data.isEmpty);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Messungen exportieren'.i18n),
      icon: Icon(Icons.mobile_screen_share_outlined, color: Theme.of(context).primaryColor),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messungen:'.i18n,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...selectedTrips
                .mapToList((key, value) => _tripSelectionTile(key, value))
                .spaceWith(const SizedBox(height: 8)),
            const SizedBox(height: 15),
            Text(
              'Dateiformat:'.i18n,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _fileFormatSelectionTile(false),
            const SizedBox(height: 10),
            _fileFormatSelectionTile(true),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(
            'Abbrechen'.i18n,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Builder(builder: (context) {
          return TextButton(
            onPressed: () async {
              List<Trip> selection = selectedTrips.keys.where((e) => selectedTrips[e]!).toList();
              if (selection.isEmpty) return;
              String location = await createTemporaryFile(selection);
              if (!context.mounted) return;
              final box = context.findRenderObject() as RenderBox?;
              await Share.shareXFiles(
                [XFile(location)],
                sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
              );
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
            ),
            child: Text(
              'Teilen'.i18n,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );
        }),
      ],
    );
  }

  Future<String> createTemporaryFile(List<Trip> selection) async {
    String cache = (await getApplicationCacheDirectory()).path;
    if (!exportAsCsv) {
      // Create a JSON file
      if (selection.length == 1) {
        Trip trip = selection.first;
        String fileName = '${trip.deviceDisplayName}-${trip.start!.toIso8601String()}';
        String path = '$cache/$fileName.json';
        File(path).writeAsStringSync(json.encode(trip.toJson()));
        return path;
      } else {
        String fileName = 'Routes-${DateTime.now().toIso8601String()}';
        String path = '$cache/$fileName.json';
        Map<String, dynamic> map = {
          'version': 'Luftdaten.at JSON Collection v1.0',
          'trips': selection.map((e) => e.toJson()).toList(),
        };
        File(path).writeAsStringSync(json.encode(map));
        return path;
      }
    } else {
      // Create a CSV file
      if (selection.length == 1) {
        Trip trip = selection.first;
        String fileName = '${trip.deviceDisplayName}-${trip.start!.toIso8601String()}';
        String path = '$cache/$fileName.csv';
        File(path).writeAsStringSync(await trip.toCsv());
        return path;
      } else {
        String fileName = 'Routes-${DateTime.now().toIso8601String()}';
        String path = '$cache/$fileName.csv';
        Trip temp = Trip(
          deviceDisplayName: 'unknown',
          deviceFourLetterCode: 'unkn',
          deviceChipId: const ChipId.unknown(),
          deviceModel: LDDeviceModel.unknownPortable,
        );
        for (Trip trip in selection) {
          temp.data.addAll(trip.data);
        }
        File(path).writeAsStringSync(await temp.toCsv());
        return path;
      }
    }
  }

  void cleanUp(String file) {
    File(file).delete();
  }

  Widget _tripSelectionTile(Trip trip, bool selected) {
    String tripStartDate = DateFormat('dd.MM.yyyy').format(trip.start!);
    String tripEndDate = DateFormat('dd.MM.yyyy').format(trip.end!);
    bool endDateSameAsStartDate = tripStartDate == tripEndDate;
    String tripDateRange = '$tripStartDate${endDateSameAsStartDate ? '' : '- $tripEndDate'}';

    String tripStartTime = DateFormat('HH:mm').format(trip.start!);
    String tripEndTime = DateFormat('HH:mm').format(trip.end!);
    String tripTimeRange = '$tripStartTime - $tripEndTime';

    return InkWell(
      onTap: () {
        setState(() {
          selectedTrips[trip] = !selected;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  selectedTrips[trip] = val;
                });
              },
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.deviceDisplayName ?? 'Imported trip',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16),
                      const SizedBox(width: 3),
                      Text(tripDateRange),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, size: 16),
                      const SizedBox(width: 3),
                      Text(tripTimeRange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileFormatSelectionTile(bool csv) {
    bool selected = csv == exportAsCsv;
    return InkWell(
      onTap: () {
        setState(() {
          exportAsCsv = csv;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        child: Row(
          children: [
            Radio(
              value: csv,
              groupValue: exportAsCsv,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    exportAsCsv = val;
                  });
                }
              },
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    csv ? 'CSV'.i18n : 'Luftdaten.at JSON (empfohlen)'.i18n,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    csv
                        ? 'Zum Export in andere Software.'
                        : 'Zur Verwendung innerhalb von Luftdaten.at-Produkten.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension MapToList<A, B, C> on Map<A, B> {
  List<C> mapToList(C Function(A key, B value) mapping) {
    List<C> list = [];
    for (MapEntry<A, B> entry in entries) {
      list.add(mapping(entry.key, entry.value));
    }
    return list;
  }
}