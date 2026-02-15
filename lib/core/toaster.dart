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
import 'package:fluttertoast/fluttertoast.dart';

import 'env.dart';

class Toaster {
  static void showToast({
    required String message,
    required Color backgroundColor,
    Color? textColor,
    IconData? icon,
    bool padded = false,
  }) {
    Widget toast = Padding(
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

  static void showSuccessToast(String message, {bool padded = false}) =>
      showToast(
        message: message,
        backgroundColor: Colors.greenAccent,
        textColor: Colors.black,
        icon: Icons.check,
        padded: padded,
      );

  static void showFailureToast(String message, {bool padded = false}) =>
      showToast(
        message: message,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        icon: Icons.error_outline,
        padded: padded,
      );
}
