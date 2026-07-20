import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:luftdaten.at/core/app/logging.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/core/io/app_file_saver.dart';
import 'package:luftdaten.at/core/io/log_exporter.dart';
import 'package:luftdaten.at/features/measurements/presentation/pages/logging_page.i18n.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';
import 'package:share_plus/share_plus.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:intl/intl.dart';

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
    final result = await exportLogFile(
      exportText: logger.toExportText(),
      tryAndroidSaveDialog: Platform.isAndroid,
      fileSaver: getIt<AppFileSaver>(),
      shareFile: (filePath, fileName) async {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(filePath, mimeType: 'text/plain', name: fileName)],
          subject: 'Luftdaten.at log',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        );
      },
    );

    if (!context.mounted) return;

    switch (result.outcome) {
      case LogExportOutcome.empty:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Keine Log-Einträge zum Exportieren.'.i18n)),
        );
      case LogExportOutcome.saved:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.savedPath!)),
        );
      case LogExportOutcome.shared:
        break;
      case LogExportOutcome.failed:
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
