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
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      state++;
      if (state >= 4) state = 0;
    });
    _loop();
  }

  @override
  Widget build(BuildContext context) =>
      Text('.' * state + (widget.fixedWidth ? '\u2009' * (3 - state) : ''), style: widget.style);
}
