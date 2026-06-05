import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted or solid translucent panel (hybrid glass UI).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.blur = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.margin,
    this.border,
    this.color,
    this.connectedAccent = false,
  });

  final Widget child;
  final bool blur;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Color? color;
  final bool connectedAccent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = color ??
        scheme.surfaceContainerHigh.withValues(alpha: blur ? 0.75 : 0.92);
    final resolvedBorder = border ??
        Border.all(
          color: connectedAccent
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        );

    final borderSide = resolvedBorder is Border
        ? resolvedBorder.top
        : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5));

    Widget content = Material(
      color: fill,
      elevation: blur ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: borderSide,
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (blur) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(borderRadius: borderRadius, child: content);
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
