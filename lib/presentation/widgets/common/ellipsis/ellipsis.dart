import 'package:flutter/material.dart';

class Ellipsis extends StatefulWidget {
  const Ellipsis({super.key, this.style, this.fixedWidth = false});

  final TextStyle? style;
  final bool fixedWidth;

  @override
  State<Ellipsis> createState() => _EllipsisState();
}

class _EllipsisState extends State<Ellipsis> {
  int state = 0;

  @override
  void initState() {
    _loop();
    super.initState();
  }

  void _loop() async {
    if(!mounted) return;
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      state++;
      if(state >= 4) state = 0;
    });
    _loop();
  }

  @override
  Widget build(BuildContext context) {
    return Text('.' * state + (widget.fixedWidth ? ' ' * (3 - state) : ''), style: widget.style);
  }
}
