import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

class LdLogger extends ChangeNotifier with LogPrinter {
  static final LdLogger I = LdLogger._();
  LdLogger._();

  List<LogEvent> messages = [];

  @override
  List<String> log(LogEvent event) {
    // TODO also record level
    add(event);
    return [event.message];
  }

  void add(LogEvent message) {
    messages.add(message);
    notifyListeners();
  }
}