import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:luftdaten.at/controller/air_station_config_wizard_controller.dart';
import 'package:luftdaten.at/page/air_station_config_wizard_page.dart';

import 'change_notifier_builder.dart';
import 'dashboard_station_tile.i18n.dart';

class AirStationWizardDashboardTile extends StatefulWidget {
  const AirStationWizardDashboardTile(this.controller, {super.key});

  final AirStationConfigWizardController controller;

  @override
  State<AirStationWizardDashboardTile> createState() => _AirStationWizardDashboardTileState();
}

class _AirStationWizardDashboardTileState extends State<AirStationWizardDashboardTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _WizardTileStatus status;
    switch (widget.controller.stage) {
      case AirStationConfigWizardStage.gpsPermissionMissing:
      case AirStationConfigWizardStage.setLocation:
      case AirStationConfigWizardStage.verifyingDeviceState:
      case AirStationConfigWizardStage.deviceDoesNotSupportBLE:
      case AirStationConfigWizardStage.bluetoothTurnedOff:
      case AirStationConfigWizardStage.blePermissionMissing:
      case AirStationConfigWizardStage.scanningForDevices:
      case AirStationConfigWizardStage.scanFailed:
      case AirStationConfigWizardStage.attemptingConnection:
      case AirStationConfigWizardStage.deviceNotVisible:
      case AirStationConfigWizardStage.deviceNotVisibleButBLEButtonBlue:
      case AirStationConfigWizardStage.deviceNotVisibleAndBLEButtonNotBlue:
      case AirStationConfigWizardStage.connectionFailed:
      case AirStationConfigWizardStage.loadingConfig:
      case AirStationConfigWizardStage.failedToLoadConfig:
        status = _WizardTileStatus.configureNow;
        break;
      case AirStationConfigWizardStage.editSettings:
      case AirStationConfigWizardStage.configureWifiChoice:
      case AirStationConfigWizardStage.editWifi:
      case AirStationConfigWizardStage.sending:
      case AirStationConfigWizardStage.configTransmissionFailed:
      case AirStationConfigWizardStage.connectionLostAndNotReestablished:
      case AirStationConfigWizardStage.loadingStatus:
      case AirStationConfigWizardStage.pingFailed:
      case AirStationConfigWizardStage.configInvalid:
      case AirStationConfigWizardStage.configSuccess:
      case AirStationConfigWizardStage.checkLed:
      case AirStationConfigWizardStage.genericWifiFailure:
        status = _WizardTileStatus.continueConfiguration;
        break;
      case AirStationConfigWizardStage.waitingForFirstData:
        status = _WizardTileStatus.waitingForData;
        break;
      case AirStationConfigWizardStage.firstDataSuccess:
        status = _WizardTileStatus.dataReceivedSuccess;
        break;
      case AirStationConfigWizardStage.firstDataFailed:
        status = _WizardTileStatus.dataNotReceived;
        break;
      case AirStationConfigWizardStage.firstDataCheckFailed:
        status = _WizardTileStatus.dataReceptionError;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ChangeNotifierBuilder(
          notifier: widget.controller,
          builder: (context, controller) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 70,
              decoration: BoxDecoration(
                color: _getColor(status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AirStationConfigWizardPage(controller: controller),
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
                                _getTitleAndSubtitle(status)[0],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(_getTitleAndSubtitle(status)[1]),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildStatus(status),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AirStationConfigWizardPage(controller: controller),
                            ));
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }

  Widget _buildStatus(_WizardTileStatus status) {
    switch (status) {
      case _WizardTileStatus.configureNow:
      case _WizardTileStatus.continueConfiguration:
        return Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.primary);
      case _WizardTileStatus.waitingForData:
        return SpinKitDualRing(
          color: Theme.of(context).primaryColor,
          size: 20,
          lineWidth: 2,
        );
      case _WizardTileStatus.dataReceivedSuccess:
        return const Icon(Icons.check_circle_outline, color: Colors.green);
      case _WizardTileStatus.dataNotReceived:
      case _WizardTileStatus.dataReceptionError:
        return const Icon(Icons.cancel_outlined, color: Colors.red);
    }
  }

  Color _getColor(_WizardTileStatus status) {
    switch (status) {
      case _WizardTileStatus.configureNow:
      case _WizardTileStatus.continueConfiguration:
      case _WizardTileStatus.waitingForData:
        return Theme.of(context).colorScheme.primaryContainer;
      case _WizardTileStatus.dataReceivedSuccess:
        return Colors.green.shade50;
      case _WizardTileStatus.dataNotReceived:
      case _WizardTileStatus.dataReceptionError:
        return Colors.red.shade50;
    }
  }

  List<String> _getTitleAndSubtitle(_WizardTileStatus status) {
    switch (status) {
      case _WizardTileStatus.configureNow:
        return ['Jetzt konfigurieren'.i18n, widget.controller.id.split('-').last];
      case _WizardTileStatus.continueConfiguration:
        return ['Konfiguration fortsezten'.i18n, widget.controller.id.split('-').last];
      case _WizardTileStatus.waitingForData:
        return ['Warte auf Daten'.i18n, widget.controller.id.split('-').last];
      case _WizardTileStatus.dataReceivedSuccess:
        return [
          'Daten empfangen'.i18n,
          'Tippen, um abzuschließen'.i18n,
        ];
      case _WizardTileStatus.dataNotReceived:
        return [
          'Keine Daten empfangen'.i18n,
          'Tippen, um zu beheben'.i18n,
        ];
      case _WizardTileStatus.dataReceptionError:
        return [
          'Verbindungsfehler'.i18n,
          'Tippen, um zu beheben'.i18n,
        ];
    }
  }
}

enum _WizardTileStatus {
  configureNow,
  continueConfiguration,
  waitingForData,
  dataReceivedSuccess,
  dataNotReceived,
  dataReceptionError,
}
