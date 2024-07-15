import 'package:flutter/material.dart';

class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const ChangeNotifierBuilder({super.key, required this.notifier, required this.builder});

  final T notifier;
  final Widget Function(BuildContext context, T notifier) builder;

  @override
  State<StatefulWidget> createState() => _ChangeNotifierBuilderState<T>();
}

class _ChangeNotifierBuilderState<T extends ChangeNotifier> extends State<ChangeNotifierBuilder<T>> {
  @override
  void initState() {
    widget.notifier.addListener(setStateCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.notifier);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(setStateCallback);
    super.dispose();
  }

  void setStateCallback() {
    setState(() {});
  }
}

class MultiChangeNotifierRefresher<T extends ChangeNotifier> extends StatefulWidget {
  const MultiChangeNotifierRefresher({super.key, required this.notifiers, required this.builder});

  final List<T> notifiers;
  final Widget Function(BuildContext) builder;

  @override
  State<StatefulWidget> createState() => _MultiChangeNotifierRefresherState<T>();
}

class _MultiChangeNotifierRefresherState<T extends ChangeNotifier> extends State<MultiChangeNotifierRefresher<T>> {
  @override
  void initState() {
    for (T e in widget.notifiers) {
      e.addListener(setStateCallback);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void dispose() {
    for (T e in widget.notifiers) {
      e.removeListener(setStateCallback);
    }
    super.dispose();
  }

  void setStateCallback() {
    setState(() {});
  }
}

class NullableChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const NullableChangeNotifierBuilder({super.key, this.notifier, required this.builder});

  final T? notifier;
  final Widget Function(BuildContext context, T? notifier) builder;

  @override
  State<StatefulWidget> createState() => _NullableChangeNotifierBuilderState<T>();
}

class _NullableChangeNotifierBuilderState<T extends ChangeNotifier> extends State<NullableChangeNotifierBuilder<T>> {
  @override
  void initState() {
    widget.notifier?.addListener(setStateCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.notifier);
  }

  @override
  void dispose() {
    widget.notifier?.removeListener(setStateCallback);
    super.dispose();
  }

  void setStateCallback() {
    setState(() {});
  }
}
