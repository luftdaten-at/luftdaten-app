import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:luftdaten.at/controller/toaster.dart';
import 'package:luftdaten.at/controller/workshop_controller.dart';
import 'package:luftdaten.at/model/workshop_configuration.dart';
import 'package:luftdaten.at/util/day.dart';

import '../main.dart';
import '../widget/code_field.dart';
import 'enter_workshop_page.i18n.dart';

class EnterWorkshopPage extends StatefulWidget {
  const EnterWorkshopPage({super.key, this.ak = false});

  final bool ak;

  static const String route = 'enter-ws';

  @override
  State<EnterWorkshopPage> createState() => _EnterWorkshopPageState();
}

class _EnterWorkshopPageState extends State<EnterWorkshopPage> with TickerProviderStateMixin {
  String workshopId = '';

  _Status status = _Status.enterId;

  late AnimationController animation;

  WorkshopConfiguration? config;

  @override
  void initState() {
    animation = AnimationController(vsync: this)
      ..duration = const Duration(seconds: 3)
      ..forward()
      ..addListener(() {
        if (animation.isCompleted) {
          animation.repeat();
        }
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.ak ? 'Messkampagne beitreten' : 'Workshop beitreten'.i18n, style: const TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).primaryColor,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: buildForStatus(),
        ),
      ),
    );
  }

  Widget buildForStatus() {
    switch (status) {
      case _Status.loading:
        return Center(
            child: LottieBuilder.asset(
          'assets/lottie/loading.json',
          controller: animation,
          frameRate: FrameRate.max,
        ));
      case _Status.displayDetails:
        return Stack(
          key: const Key('enter-ws-details'),
          children: [
            const Column(
              mainAxisSize: MainAxisSize.max,
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Spacer(flex: 1),
                        Text(
                          'Workshop %s'.i18n.fill([workshopId.formatAsId]),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(config!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(config!.description),
                    const SizedBox(height: 2),
                    if (config!.start.date == config!.end.date)
                      Row(
                        children: [
                          const Icon(Icons.calendar_month),
                          const SizedBox(width: 5),
                          Text(DateFormat('dd.MM.yyyy'.i18n).format(config!.start.toLocal())),
                        ],
                      ),
                    if (config!.start.date != config!.end.date)
                      Row(
                        children: [
                          const Icon(Icons.start),
                          const SizedBox(width: 5),
                          Text('%s Uhr'.i18n.fill([
                            DateFormat('dd.MM.yyyy, HH:mm'.i18n).format(config!.start.toLocal())
                          ])),
                        ],
                      ),
                    const SizedBox(height: 2),
                    if (config!.start.date == config!.end.date)
                      Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 5),
                          Text(
                              "${DateFormat('HH:mm'.i18n).format(config!.start.toLocal())} - ${DateFormat('HH:mm'.i18n).format(config!.end.toLocal())}"),
                        ],
                      ),
                    if (config!.start.date != config!.end.date)
                      Row(
                        children: [
                          const Icon(Icons.keyboard_tab),
                          const SizedBox(width: 5),
                          Text('%s Uhr'.i18n.fill([
                            DateFormat('dd.MM.yyyy, HH:mm'.i18n).format(config!.end.toLocal())
                          ])),
                        ],
                      ),
                    const SizedBox(height: 10),
                    if (config!.end.isBefore(DateTime.now().toUtc()))
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.red.shade900),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                'Dieser Workshop liegt in der Vergangenheit.'.i18n,
                              )),
                            ],
                          ),
                        ),
                      ),
                    if (config!.end.isBefore(DateTime.now().toUtc())) const SizedBox(height: 10),
                    if (config!.end.isBefore(DateTime.now().toUtc()))
                      Row(
                        children: [
                          const Spacer(flex: 1),
                          FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Zurück'.i18n)),
                        ],
                      ),
                    if (config!.start.isAfter(DateTime.now().toUtc()))
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.red.shade900),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                'Dieser Workshop hat noch nicht begonnen. '
                                        'Du kannst erst nach dem Beginn des Workshops beitreten.'
                                    .i18n,
                              )),
                            ],
                          ),
                        ),
                      ),
                    if (config!.start.isAfter(DateTime.now().toUtc())) const SizedBox(height: 10),
                    if (config!.start.isAfter(DateTime.now().toUtc()))
                      Row(
                        children: [
                          const Spacer(flex: 1),
                          FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Zurück'.i18n)),
                        ],
                      ),
                    if (config!.end.isAfter(DateTime.now().toUtc()) &&
                        config!.start.isBefore(DateTime.now().toUtc()))
                      Row(
                        children: [
                          const Spacer(flex: 1),
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Abbrechen'.i18n)),
                          const SizedBox(width: 5),
                          FilledButton(
                              onPressed: () {
                                getIt<WorkshopController>().currentWorkshop = config;
                                Navigator.of(context).pop(true);
                                Toaster.showSuccessToast(
                                  'Workshop erfolgreich beigetreten.'.i18n,
                                  padded: true,
                                );
                              },
                              child: Text('Beitreten'.i18n)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      default:
        return Stack(
          key: const Key('enter-ws-id'),
          children: [
            const Column(
              mainAxisSize: MainAxisSize.max,
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Beitritts-Code'.i18n,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Spacer(flex: 1),
                        CodeField(
                          onChanged: (val) {
                            workshopId = val;
                            setState(() {});
                          },
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Spacer(flex: 1),
                        FilledButton(
                            onPressed: workshopId.length == 6
                                ? () async {
                                    setState(() {
                                      status = _Status.loading;
                                    });
                                    try {
                                      config = await getIt<WorkshopController>()
                                          .loadWorkshopDetails(workshopId);
                                      status = _Status.displayDetails;
                                    } on ConnectionError {
                                      status = _Status.enterId;
                                      Toaster.showFailureToast(
                                          'Verbindungsfehler. Bitte überprüfe deine Internetverbindung.'
                                              .i18n);
                                    } on InvalidIdError {
                                      status = _Status.enterId;
                                      Toaster.showFailureToast('Beitritts-Code ungültig.'.i18n);
                                    } catch (_, trace) {
                                      status = _Status.enterId;
                                      logger.e('Failed to parse workshop details. Trace:');
                                      trace.toString().split('\n').forEach((e) => logger.e(e));
                                      Toaster.showFailureToast('Ein Fehler ist aufgetreten.'.i18n);
                                    }
                                    setState(() {});
                                  }
                                : null,
                            child: Text('Beitreten'.i18n)),
                        const Spacer(flex: 1),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(widget.ak ? 'Was ist mein Beitritts-Code?' : 'Wie kann ich teilnehmen?'.i18n,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(widget.ak ? 'Der Beitritts-Code identifiziert deine Messdaten mit deinem Arbeitsplatz. Die erhältst ihn über Deinen Betriebsrat.' :
                    'Wir organisieren regelmäßig Luftqualitäts-Workshops in ganz Österreich. '
                            'Du würdest genre mitmachen? Die Termine der nächsten Workshops '
                            'findest du auf unserer Webseite!'
                        .i18n),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }
}

enum _Status {
  enterId,
  loading,
  displayDetails,
}
