import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luftdaten.at/controller/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/controller/app_settings.dart';
import 'package:luftdaten.at/controller/device_manager.dart';
import 'package:luftdaten.at/controller/favorites_manager.dart';
import 'package:luftdaten.at/controller/news_controller.dart';
import 'package:luftdaten.at/controller/workshop_controller.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/model/ble_device.dart';
import 'package:luftdaten.at/page/enter_workshop_page.dart';
import 'package:luftdaten.at/page/favorites_page.dart';
import 'package:luftdaten.at/widget/air_station_wizard_dashboard_tile.dart';
import 'package:luftdaten.at/widget/change_notifier_builder.dart';
import 'package:luftdaten.at/widget/dashboard_station_tile.dart';
import 'package:luftdaten.at/widget/ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/news_item.dart';
import 'dashboard_page.i18n.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<StatefulWidget> createState() => _DashboardPage();
}

class _DashboardPage extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
        notifier: AppSettings.I,
        builder: (context, _) {
          return Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: MultiChangeNotifierRefresher(
                  notifiers: [
                    getIt<NewsController>(),
                    getIt<DeviceManager>(),
                    getIt<FavoritesManager>(),
                    AirStationConfigWizardController.activeControllers,
                  ],
                  builder: (_) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (getIt<NewsController>().hasUnreadItems()) ..._buildNewsSection(),
                      if (AppSettings.I.dashboardShowAirStations) ..._buildAirStationSection(),
                      if (AppSettings.I.dashboardShowFavorites) ..._buildFavoritesSection(),
                      if (AppSettings.I.dashboardShowPortables) ..._buildPortablesSection(),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  List<Widget> _buildNewsSection() {
    List<NewsItem> items = getIt<NewsController>().items;
    List<Widget> content = items
        .map((e) => _buildTappableTile(
            title: e.title,
            subtitle: e.description,
            // TODO add dismiss button
            onTap: () {
              showLDDialog(context,
                  title: e.title,
                  icon: Icons.newspaper,
                  text: e.description,
                  actions: [
                    LDDialogAction(
                      label: 'Archivieren'.i18n,
                      filled: false,
                      onTap: () {
                        getIt<NewsController>().archiveItem(e);
                      },
                    ),
                    LDDialogAction(
                      label: 'Mehr lesen'.i18n,
                      filled: true,
                      onTap: () {
                        if (e.url != null) {
                          launchUrl(Uri.parse(e.url!));
                        }
                      },
                    ),
                  ]);
            }))
        .toList();
    return [
      _buildSectionHeading('Neues in der App:'.i18n, []),
      ...content,
      const SizedBox(height: 15),
    ];
  }

  List<Widget> _buildAirStationSection() {
    bool hasStations = getIt<DeviceManager>().devices.where((e) => !e.portable).isNotEmpty;
    List<Widget> content;
    if (!hasStations) {
      content = [
        const SizedBox(height: 5),
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Du hast noch keine Air Station konfiguriert.'.i18n,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        _buildTappableTile(
            title: 'Neues Gerät hinzufügen'.i18n,
            onTap: () {
              getIt<PageController>().jumpToPage(3);
            }),
      ];
    } else {
      List<BleDevice> devices =
          getIt<DeviceManager>().devices.where((e) => e.model == LDDeviceModel.station).toList();
      content = [];
      for (BleDevice device in devices) {
        if (AirStationConfigWizardController.activeControllers.containsKey(device.bleName)) {
          // Show wizard tile
          content.add(AirStationWizardDashboardTile(
            AirStationConfigWizardController(device.bleName),
          ));
        } else {
          // Show station tile
          content.add(DashboardStationTile(device: device));
        }
      }
    }
    return [
      _buildSectionHeading('Meine Air-Station-Geräte:'.i18n, [
        _buildHideButton(() {
          setState(() {
            AppSettings.I.dashboardShowAirStations = false;
          });
        }),
      ]),
      ...content,
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildFavoritesSection() {
    bool hasFavorites = getIt<FavoritesManager>().favorites.isNotEmpty;
    return [
      _buildSectionHeading('Meine Favoriten:'.i18n, [
        _buildOtherButton(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.of(context).pushNamed(FavoritesPage.route),
        ),
        const SizedBox(width: 4),
        _buildHideButton(() {
          setState(() {
            AppSettings.I.dashboardShowFavorites = false;
          });
        }),
      ]),
      const SizedBox(height: 5),
      if (!hasFavorites) ...[
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Füge Messstationen von der Luftkarte zu deinen Favoriten hinzu, um einen schnellen Überblick über die Luftqualität in deiner Umgebung zu bekommen. Tippe dazu auf eine Messstation auf der Luftkarte und wähle das Lesezeichen im rechts oberen Eck des Dialogfeldes.'
                    .i18n,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(width: 17),
          ],
        ),
        _buildTappableTile(
            title: 'Zur Luftkarte',
            onTap: () {
              getIt<PageController>().jumpToPage(1);
            }),
      ],
      if (hasFavorites)
        SizedBox(
          height: 80 * getIt<FavoritesManager>().favorites.length.toDouble(),
          child: Builder(builder: (context) {
            List<DashboardStationTile> children = getIt<FavoritesManager>()
                .favorites
                .map((e) => DashboardStationTile(
                      favorite: e,
                      key: Key(e.id.toString()),
                      dragController: DragController(),
                    ))
                .toList();
            return ReorderableListView(
              physics: const NeverScrollableScrollPhysics(),
              proxyDecorator: (Widget child, int index, Animation<double> animation) {
                return child;
              },
              onReorderStart: (int index) {
                children[index].dragController?.isDragging = true;
              },
              onReorderEnd: (int index) {
                try {
                  children[index].dragController?.isDragging = false;
                } catch(_) {}
              },
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  List<Favorite> items = getIt<FavoritesManager>().favorites;
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final Favorite item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                  getIt<FavoritesManager>().save();
                });
              },
              children: children,
            );
          }),
        ),
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildPortablesSection() {
    bool hasPortables = getIt<DeviceManager>().devices.where((e) => e.portable).isNotEmpty;
    return [
      _buildSectionHeading('Tragbare Messungen:'.i18n, [
        _buildHideButton(() {
          setState(() {
            AppSettings.I.dashboardShowPortables = false;
          });
        }),
      ]),
      if (!hasPortables) ...[
        const SizedBox(height: 5),
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Du hast noch keine tragbaren Messgeräte (z. B. Air aRound) konfiguriert.'.i18n,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        _buildTappableTile(
            title: 'Neues Gerät hinzufügen'.i18n,
            onTap: () {
              getIt<PageController>().jumpToPage(3);
            }),
      ],
      if (hasPortables) ...[
        const SizedBox(height: 5),
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Messungen können auf den Luftkarte- und Messwerte-Seiten gestartet und beendet werden.'
                    .i18n,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        _buildTappableTile(
            title: 'Zur Messwerte-Seite'.i18n,
            onTap: () {
              getIt<PageController>().jumpToPage(2);
            }),
      ],
      ChangeNotifierBuilder(
        notifier: getIt<WorkshopController>(),
        builder: (context, workshopController) {
          if(workshopController.currentWorkshop == null) {
            return _buildTappableTile(
              title: 'An Workshop teilnehmen'.i18n,
              onTap: () {
                Navigator.of(context).pushNamed(EnterWorkshopPage.route);
              });
          } else {
            return _buildTappableTile(
                title: 'Workshop-Details'.i18n,
                onTap: () {
                  showLDDialog(
                    context,
                    title: 'Workshop läuft'.i18n,
                    icon: Icons.send_to_mobile,
                    text: 'Du sendest Messwerte als Teil des Workshops „%s“. '
                        'Dieser Workshop läuft noch bis %s, %s Uhr.'
                        .i18n.fill(
                      [
                        workshopController.currentWorkshop!.name,
                        DateFormat('dd.MM.yyyy'.i18n)
                            .format(workshopController.currentWorkshop!.end.toLocal()),
                        DateFormat('HH:mm'.i18n)
                            .format(workshopController.currentWorkshop!.end.toLocal()),
                      ],
                    ),
                    actions: [
                      LDDialogAction(
                        label: 'Austreten'.i18n,
                        onTap: () {
                          showLDDialog(
                            context,
                            title: 'Workshop verlassen'.i18n,
                            icon: Icons.exit_to_app,
                            text: 'Aus dem aktuellen Workshop austreten?',
                            color: Colors.red,
                            actions: [
                              LDDialogAction.cancel(),
                              LDDialogAction(
                                label: 'Austreten'.i18n,
                                filled: true,
                                onTap: () {
                                  workshopController.exitWorkshop();
                                },
                              ),
                            ],
                          );
                        },
                        filled: false,
                      ),
                      LDDialogAction.dismiss(filled: true),
                    ],
                  );
                });
          }
        }
      ),
      const SizedBox(height: 15),
    ];
  }

  Widget _buildTappableTile(
      {required String title, String? subtitle, required void Function() onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 0),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
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
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String title, List<Widget> actions) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...actions,
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildHideButton(void Function() onHideSelected) {
    return _buildOtherButton(
      onTap: () {
        showLDDialog(
          context,
          title: 'Reiter verstecken?'.i18n,
          icon: Icons.hide_source,
          color: Colors.red,
          text:
              'Diesen Reiter verstecken? Versteckte Reiter können in den Einstellungen wieder aktiviert werden.'
                  .i18n,
          actions: [
            LDDialogAction(label: 'Abbrechen'.i18n, filled: false),
            LDDialogAction(label: 'Verstecken'.i18n, filled: true, onTap: onHideSelected),
          ],
        );
      },
      icon: Icons.close,
    );
  }

  Widget _buildOtherButton({required IconData icon, required void Function() onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Icon(icon),
    );
  }
}
