import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages - nested is transitive from provider
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

/// Pumps a widget with optional Provider overrides for widget tests.
Widget pumpApp(Widget child, {List<SingleChildWidget> overrides = const []}) {
  return MaterialApp(
    home: overrides.isEmpty
        ? child
        : MultiProvider(providers: overrides, child: child),
  );
}
