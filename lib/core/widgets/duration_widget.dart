/*
   Copyright (C) 2023 Thomas Ogrisegg for luftdaten.at

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

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
