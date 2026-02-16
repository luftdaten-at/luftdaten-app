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
import 'package:flutter/services.dart';

class CodeField extends StatefulWidget {
  const CodeField({super.key, this.onChanged});

  final void Function(String value)? onChanged;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  TextEditingController textController = TextEditingController();
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    focusNode.requestFocus();
    focusNode.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 50,
      child: Stack(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: Theme.of(context).scaffoldBackgroundColor,
                selectionColor: Theme.of(context).scaffoldBackgroundColor,
                selectionHandleColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            child: Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: TextField(
                  controller: textController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                  ],
                  onChanged: (val) {
                    setState(() {});
                    widget.onChanged?.call(val);
                  },
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    fillColor: Colors.transparent,
                  ),
                  enableInteractiveSelection: false,
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          IgnorePointer(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                nthSegment(0),
                nthSegment(1),
                nthSegment(2),
                textSegment('–'),
                nthSegment(3),
                nthSegment(4),
                nthSegment(5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget nthSegment(int n) {
    final text = textController.text.length > n ? textController.text[n].toUpperCase() : '';
    return textSegment(text);
  }

  Widget textSegment(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
      child: Container(
        width: 20,
        color: text.isEmpty
            ? (focusNode.hasFocus ? Colors.blue.shade100 : Colors.blue.shade50)
            : Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
      ),
    );
  }
}
