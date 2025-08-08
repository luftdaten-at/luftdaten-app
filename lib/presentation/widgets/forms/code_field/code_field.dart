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
    focusNode.addListener(() {
      setState(() {});
    });
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
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextField(
                    controller: textController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
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
                );
              }
            ),
          ),
          IgnorePointer(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
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
    String text;
    if (textController.text.length > n) {
      text = textController.text[n].toUpperCase();
    } else {
      text = '';
    }
    return textSegment(text);
  }

  Widget textSegment(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
      child: Container(
        width: 20,
        color: text.isEmpty ? (focusNode.hasFocus ? Colors.blue.shade100 : Colors.blue.shade50) : Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
