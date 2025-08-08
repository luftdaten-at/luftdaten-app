import 'package:flutter/material.dart';

class DurationWidget extends StatefulWidget {
  const DurationWidget({super.key, required this.initialTime, required this.builder});

  final DateTime initialTime;
  final Widget Function(BuildContext, Duration) builder;

  @override
  State<DurationWidget> createState() => _DurationWidgetState();
}

class _DurationWidgetState extends State<DurationWidget> {
  bool started = false;

  void tick() async {
    if (!mounted) return;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 200));
    tick();
  }

  @override
  Widget build(BuildContext context) {
    if (!started) {
      started = true;
      Future.delayed(const Duration(milliseconds: 200)).then((_) => tick());
    }
    return widget.builder(context, DateTime.now().difference(widget.initialTime));
  }
}
