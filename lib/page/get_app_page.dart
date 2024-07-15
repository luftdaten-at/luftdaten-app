import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:luftdaten.at/page/get_app_page.i18n.dart';
import 'package:luftdaten.at/widget/ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GetAppPage extends StatelessWidget {
  const GetAppPage({super.key});

  static const String route = 'get-app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Luftdaten.at App'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Image.asset('assets/icon-round-2.png', width: 100),
          const Text('Luftdaten.at', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
          const SizedBox(height: 30),
          QrImageView(data: 'https://luftdaten.at/mobile-app/', size: 140),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('https://luftdaten.at/mobile-app/', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
              IconButton(
                onPressed: () {
                  FlutterClipboard.copy('https://luftdaten.at/mobile-app/');
                  snackMessage(context, 'Link kopiert'.i18n);
                },
                icon: const Icon(Icons.copy_rounded),
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
