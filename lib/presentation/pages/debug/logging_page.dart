import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../../../core/services/logging/ld_logger.dart';
import 'logging_page.i18n.dart';
import '../../widgets/common/change_notifier/change_notifier_builder.dart';
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

  void setStateCallback() {
    setState(() {});
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
            onPressed: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
              );
            },
            icon: const Icon(Icons.vertical_align_bottom, color: Colors.white),
            tooltip: 'Zum Ende scrollen'.i18n,
          )
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
