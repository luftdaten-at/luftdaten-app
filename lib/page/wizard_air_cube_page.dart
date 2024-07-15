import 'package:flutter/material.dart';
import 'package:i18n_extension/default.i18n.dart';

class WizardAirCubePage extends StatefulWidget {
  const WizardAirCubePage({super.key});

  @override
  State<WizardAirCubePage> createState() => _WizardAirCubePageState();
}

class _WizardAirCubePageState extends State<WizardAirCubePage> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      child: Builder(builder: (innerContext) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text('Air Cube konfigurieren'.i18n, style: const TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(innerContext).colorScheme.primary,
            leading: IconButton(
              onPressed: () => Navigator.of(innerContext).pop(),
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Um an diesem Projekt teilzunehmen, ist ein Luftdaten.at-Nutzerkonto zur Datenverwaltung notwendig. Bitte melde dich an oder registriere dich.'
                      .i18n,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {},
                  child: Text('Anmelden oder registrieren'.i18n),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
