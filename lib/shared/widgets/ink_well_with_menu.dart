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

class InkWellWithMenu extends StatefulWidget {
  const InkWellWithMenu({
    super.key,
    this.child,
    this.borderRadius,
    this.onTap,
    required this.items,
  });

  final Widget? child;
  final BorderRadius? borderRadius;
  final List<PopupMenuItem<dynamic>> items;
  final void Function()? onTap;

  @override
  State<StatefulWidget> createState() => _InkWellWithMenuState();
}

class _InkWellWithMenuState extends State<InkWellWithMenu> {
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onTapDown: (details) => _tapPosition = details.globalPosition,
      onLongPress: () {
        final RenderBox overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
        showMenu(
          context: context,
          position: RelativeRect.fromRect(
            _tapPosition! & const Size(40, 40),
            Offset.zero & overlay.size,
          ),
          items: widget.items,
        );
      },
      borderRadius: widget.borderRadius,
      child: widget.child,
    );
  }
}
