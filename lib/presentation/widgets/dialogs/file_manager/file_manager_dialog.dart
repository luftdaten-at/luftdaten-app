import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/controller/file_handler.dart';
import 'package:luftdaten.at/controller/trip_controller.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/util/list_extensions.dart';
import 'package:luftdaten.at/widget/current_trip_export_dialog.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../model/trip.dart';
import 'file_manager_dialog.i18n.dart';

class FileManagerDialog extends StatefulWidget {
  const FileManagerDialog(this.dates, {super.key});

  final List<DateTime> dates;

  @override
  State<StatefulWidget> createState() => _FileManagerDialogState();
}

class _FileManagerDialogState extends State<FileManagerDialog> {
  Map<Trip, bool> currentSelection = {};
  late DateTime selectedDate;

  @override
  void initState() {
    selectedDate = DateTime.now();
    for (Trip trip in [
      ...getIt<TripController>().ongoingTrips.values,
      ...getIt<TripController>().loadedTrips
    ]) {
      currentSelection[trip] = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getIt<FileHandler>().getTripsForDay(selectedDate);

    return AlertDialog(
      title: Text('Messungen verwalten'.i18n),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktuelle Auswahl:'.i18n,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...currentSelection
                .map((trip, selected) => MapEntry(_tripTile(trip, selected), true))
                .keys
                .toList()
                .spaceWith(const SizedBox(height: 8)),
            if(currentSelection.isEmpty)
              Text('Keine Messungen ausgewählt.'.i18n, style: const TextStyle(fontStyle: FontStyle.italic),),
            const SizedBox(height: 15),
            Text(
              'Frühere Messungen:'.i18n,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 260,
                  child: SfDateRangePicker(
                    showNavigationArrow: true,
                    maxDate: DateTime.now(),
                    monthViewSettings: const DateRangePickerMonthViewSettings(firstDayOfWeek: 1),
                    selectionRadius: 40,
                    showActionButtons: false,
                    selectableDayPredicate: (date) {
                      for (DateTime d in widget.dates) {
                        if (d.day == date.day && d.month == date.month && d.year == date.year) {
                          return true;
                        }
                      }
                      return false;
                    },
                    onSelectionChanged: (selection) {
                      setState(() {
                        selectedDate = selection.value as DateTime;
                      });
                    },
                  ),
                ),
              ],
            ),
            FutureBuilder(
              key: Key(selectedDate.toString()),
              future: getIt<FileHandler>().getTripsForDay(selectedDate),
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitDualRing(color: Theme.of(context).primaryColor, lineWidth: 2, size: 30,),
                    ],
                  );
                }
                List<Widget> widgets = [];
                for (Trip trip in snapshot.data!) {
                  for (Trip addedTrip in currentSelection.keys) {
                    if (addedTrip.equals(trip)) {
                      trip = addedTrip;
                      break;
                    }
                  }
                  widgets.add(_tripTile(trip, currentSelection[trip] ?? false));
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widgets.spaceWith(const SizedBox(height: 8)),
                );
              },
            ),
            const SizedBox(height: 15),
            Text(
              'Aktionen:'.i18n,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () {
                    List<Trip> selectedTrips =
                        currentSelection.entries.where((e) => e.value).map((e) => e.key).toList();
                    TripController controller = getIt<TripController>();
                    for (Trip trip in selectedTrips) {
                      if (controller.ongoingTrips.values.contains(trip)) {
                        continue;
                      }
                      if (controller.loadedTrips.contains(trip)) {
                        continue;
                      }
                      // Trip was not currently displayed, add to loaded trips
                      controller.loadedTrips.add(trip);
                    }
                    for (Trip trip in [...controller.ongoingTrips.values]) {
                      if (!selectedTrips.contains(trip)) {
                        controller.ongoingTrips.removeWhere((key, value) => value == trip);
                      }
                    }
                    for (Trip trip in [...controller.loadedTrips]) {
                      if (!selectedTrips.contains(trip)) {
                        controller.loadedTrips.remove(trip);
                      }
                    }
                    controller.notifyListeners();
                    Navigator.of(context).pop();
                  },
                  child: Text('Auswahl anzeigen'.i18n),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () {
                    // TODO disable button if selection is empty
                    List<Trip> selectedTrips =
                        currentSelection.entries.where((e) => e.value).map((e) => e.key).toList();
                    Navigator.of(context).pop();
                    if (selectedTrips.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => CurrentTripExportDialog(trips: selectedTrips),
                      );
                    }
                  },
                  child: Text('Auswahl exportieren'.i18n),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Schließen'.i18n),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _tripTile(Trip trip, bool selected) {
    String tripStartDate = DateFormat('dd.MM.yyyy').format(trip.start!);
    String tripEndDate = DateFormat('dd.MM.yyyy').format(trip.end!);
    bool endDateSameAsStartDate = tripStartDate == tripEndDate;
    String tripDateRange = '$tripStartDate${endDateSameAsStartDate ? '' : '- $tripEndDate'}';

    String tripStartTime = DateFormat('HH:mm').format(trip.start!);
    String tripEndTime = DateFormat('HH:mm').format(trip.end!);
    String tripTimeRange = '$tripStartTime - $tripEndTime';

    return InkWell(
      onTap: currentSelection.containsKey(trip)
          ? () {
              setState(() {
                currentSelection[trip] = !selected;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            if (currentSelection.containsKey(trip))
              Checkbox(
                value: selected,
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    currentSelection[trip] = val;
                  });
                },
              ),
            if (!currentSelection.containsKey(trip))
              IconButton(
                onPressed: () {
                  setState(() {
                    currentSelection[trip] = true;
                  });
                },
                icon: const Icon(Icons.add),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.deviceDisplayName ?? 'Importierte Messung'.i18n,
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
}

extension _TripEquality on Trip {
  bool equals(Trip other) {
    return other.deviceFourLetterCode == deviceFourLetterCode &&
        other.data.first.timestamp == data.first.timestamp;
  }
}
