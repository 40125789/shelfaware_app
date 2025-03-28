import 'package:flutter/material.dart';

class DonationUtils {
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String cancelText = "Cancel",
    String confirmText = "Confirm",
    Color confirmColor = Colors.red,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                confirmText,
                style: TextStyle(color: confirmColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
