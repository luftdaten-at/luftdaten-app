import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../main.dart';

class Toaster {
  /// padded: Whether to add bottom padding to the toast to avoid overlapping with the bottom navigation bar
  static void showToast({
    required String message,
    required Color backgroundColor,
    Color? textColor,
    IconData? icon,
    bool padded = false,
  }) {
    Widget toast = Padding(
      // From documentation, this is the default height of the bottom navigation bar
      padding: padded ? const EdgeInsets.only(bottom: 80) : const EdgeInsets.all(0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: backgroundColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: textColor),
            if (icon != null) const SizedBox(width: 12.0),
            Flexible(child: Text(message, style: TextStyle(color: textColor))),
          ],
        ),
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 5),
      ignorePointer: true,
    );
  }

  static void showSuccessToast(String message, {bool padded = false}) => showToast(
        message: message,
        backgroundColor: Colors.greenAccent,
        textColor: Colors.black,
        icon: Icons.check,
        padded: padded,
      );

  static void showFailureToast(String message, {bool padded = false}) => showToast(
        message: message,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        icon: Icons.error_outline,
        padded: padded,
      );
}
