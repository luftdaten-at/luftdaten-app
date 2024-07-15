import 'package:flutter/material.dart';

class InkWellWithMenu extends StatefulWidget {
  const InkWellWithMenu(
      {super.key, this.child, this.borderRadius, this.onTap, required this.items});

  final Widget? child;
  final BorderRadius? borderRadius;
  final List<PopupMenuItem> items;
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
          position:
              RelativeRect.fromRect(_tapPosition! & const Size(40, 40), Offset.zero & overlay.size),
          items: widget.items,
        );
      },
      borderRadius: widget.borderRadius,
      child: widget.child,
    );
  }
}
