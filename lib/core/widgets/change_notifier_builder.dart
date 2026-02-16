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

class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const ChangeNotifierBuilder({super.key, required this.notifier, required this.builder});

  final T notifier;
  final Widget Function(BuildContext context, T notifier) builder;

  @override
  State<StatefulWidget> createState() => _ChangeNotifierBuilderState<T>();
}

class _ChangeNotifierBuilderState<T extends ChangeNotifier> extends State<ChangeNotifierBuilder<T>> {
  @override
  void initState() {
    widget.notifier.addListener(setStateCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.notifier);

  @override
  void dispose() {
    widget.notifier.removeListener(setStateCallback);
    super.dispose();
  }

  void setStateCallback() => setState(() {});
}

class MultiChangeNotifierRefresher<T extends ChangeNotifier> extends StatefulWidget {
  const MultiChangeNotifierRefresher({super.key, required this.notifiers, required this.builder});

  final List<T> notifiers;
  final Widget Function(BuildContext) builder;

  @override
  State<StatefulWidget> createState() => _MultiChangeNotifierRefresherState<T>();
}

class _MultiChangeNotifierRefresherState<T extends ChangeNotifier> extends State<MultiChangeNotifierRefresher<T>> {
  @override
  void initState() {
    for (T e in widget.notifiers) e.addListener(setStateCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);

  @override
  void dispose() {
    for (T e in widget.notifiers) e.removeListener(setStateCallback);
    super.dispose();
  }

  void setStateCallback() => setState(() {});
}

class NullableChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const NullableChangeNotifierBuilder({super.key, this.notifier, required this.builder});

  final T? notifier;
  final Widget Function(BuildContext context, T? notifier) builder;

  @override
  State<StatefulWidget> createState() => _NullableChangeNotifierBuilderState<T>();
}

class _NullableChangeNotifierBuilderState<T extends ChangeNotifier> extends State<NullableChangeNotifierBuilder<T>> {
  @override
  void initState() {
    widget.notifier?.addListener(setStateCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.notifier);

  @override
  void dispose() {
    widget.notifier?.removeListener(setStateCallback);
    super.dispose();
  }

  void setStateCallback() => setState(() {});
}
