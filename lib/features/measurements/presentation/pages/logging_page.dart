import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:luftdaten.at/core/app/logging.dart';
import 'package:luftdaten.at/features/measurements/presentation/pages/logging_page.i18n.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class LoggingPage extends StatefulWidget {
  const LoggingPage({super.key});

  static const String route = 'logging';

  @override
  State<LoggingPage> createState() => _LoggingPageState();
}

class _LoggingPageState extends State<LoggingPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _exportLog(BuildContext context) async {
    final logger = LdLogger.I;
    if (logger.messages.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keine Log-Einträge zum Exportieren.'.i18n)),
      );
      return;
    }

    try {
      final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      final fileName = 'luftdaten-log-$stamp.txt';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(logger.toExportText());

      if (!context.mounted) return;

      if (Platform.isAndroid) {
        final savedPath = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            sourceFilePath: file.path,
            fileName: fileName,
            mimeTypesFilter: ['text/plain'],
          ),
        );
        if (!context.mounted) return;
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(savedPath)),
          );
          return;
        }
      }

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/plain', name: fileName)],
        subject: 'Luftdaten.at log',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Log konnte nicht exportiert werden.'.i18n)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //List<LogMessage> messages = appController.logger.messages;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Log'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _exportLog(context),
            icon: const Icon(Icons.save_alt, color: Colors.white),
            tooltip: 'Log exportieren'.i18n,
          ),
          IconButton(
            onPressed: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
              );
            },
            icon: const Icon(Icons.vertical_align_bottom, color: Colors.white),
            tooltip: 'Zum Ende scrollen'.i18n,
          ),
        ],
      ),
      body: ChangeNotifierBuilder(
          notifier: LdLogger.I,
          builder: (context, logger) {
            return TableView.builder(
              columnCount: 1,
              rowCount: logger.messages.length + 2,
              // Add 4 empty lines at the bottom for presentation
              columnBuilder: (int index) => const TableSpan(extent: FixedTableSpanExtent(1400)),
              rowBuilder: (int index) => const TableSpan(extent: FixedTableSpanExtent(20)),
              cellBuilder: (BuildContext _, TableVicinity vicinity) {
                if (vicinity.row >= logger.messages.length) {
                  return const TableViewCell(child: SizedBox(height: 0, width: 0));
                }
                LogEvent message = logger.messages[vicinity.row];
                return TableViewCell(
                  child: Text(
                    '  ${DateFormat('yyyy-MM-dd hh:mm:ss').format(message.time)}: ${message.message}',
                  ),
                );
              },
              verticalDetails: ScrollableDetails.vertical(
                controller: _scrollController,
              ),
            );
          }),
    );
  }
}
