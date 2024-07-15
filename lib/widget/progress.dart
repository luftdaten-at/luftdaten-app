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

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ProgressWaiter extends StatefulWidget {
  final double width;
  final double height;

  const ProgressWaiter({super.key, this.width = 100, this.height = 100});

  @override
  State<ProgressWaiter> createState() => _ProgressWaiterState();
}

class _ProgressWaiterState extends State<ProgressWaiter> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.rotate(
          angle: _controller.value * 4 * math.pi,
          child: child,
        );
      },
      child: Image(
        image: const AssetImage('assets/icon-blue-full.png'),
        //opacity: _controller,
        width: widget.width,
        height: widget.height,
      ),
    );
  }
}
