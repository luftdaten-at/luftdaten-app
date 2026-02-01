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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';

class RotatingWidget extends StatefulWidget {
  const RotatingWidget({
    super.key,
    required this.controller,
    required this.duration,
    required this.child,
    this.activeChild,
  });

  final RotatingWidgetController controller;
  final Duration duration;
  final Widget child;
  final Widget? activeChild;

  @override
  State<StatefulWidget> createState() => _RotatingWidgetState();
}

class _RotatingWidgetState extends State<RotatingWidget> with TickerProviderStateMixin {
  late AnimationController animationController;
  bool isRotating = false;
  bool disposed = false;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: widget.duration);
    widget.controller._attach(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (_, animation) => Transform.rotate(
        angle: -animationController.value * 2 * pi,
        child: isRotating ? (widget.activeChild ?? widget.child) : widget.child,
      ),
    );
  }

  void startRotating() {
    if (!isRotating) {
      _continueRotation();
      isRotating = true;
    }
  }

  void _continueRotation() {
    if (widget.controller.shouldRotate && !disposed) {
      animationController.forward(from: 0);
      Future.delayed(widget.duration).then((_) => _continueRotation());
    } else {
      isRotating = false;
      if (mounted) setState(() {});
    }
  }

  void stopRotating() {}

  @override
  void dispose() {
    widget.controller.dispose();
    disposed = true;
    super.dispose();
  }
}

class RotatingWidgetController {
  _RotatingWidgetState? _child;
  bool shouldRotate = false;

  void start() {
    logger.d('Start rotation');
    shouldRotate = true;
    _child?.startRotating();
  }

  void stop() {
    logger.d('Stop rotation');
    shouldRotate = false;
    _child?.stopRotating();
  }

  void _attach(_RotatingWidgetState child) => _child = child;

  void dispose() => _child = null;
}
