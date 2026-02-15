import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pumps a widget with optional Provider overrides for widget tests.
Widget pumpApp(Widget child, {List<Override> overrides = const []}) {
  return MaterialApp(
    home: overrides.isEmpty
        ? child
        : MultiProvider(providers: overrides, child: child),
  );
}
