import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpiryIcon extends StatelessWidget {
  final Timestamp expiryTimestamp;

  const ExpiryIcon({Key? key, required this.expiryTimestamp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime expiryDate = expiryTimestamp.toDate();
    DateTime today = DateTime.now();
    int daysDifference = expiryDate.difference(today).inDays;

    IconData iconData;
    Color iconColor;

    // Adjusted logic for "Fresh", "Expiring Soon", and "Expired"
    if (daysDifference < 0) {
      // Expired items
      iconData = Icons.error;
      iconColor = Colors.red[700]!;
    } else if (daysDifference == 0) {
      // Expiring today
      iconData = Icons.warning;
      iconColor = Colors.orange[700]!;
    } else if (daysDifference <= 5) {
      // Expiring soon (within 5 days)
      iconData = Icons.warning;
      iconColor = Colors.orange[700]!;
    } else {
      // Fresh items (more than 5 days left)
      iconData = Icons.check_circle;
      iconColor = Colors.green[700]!;
    }

    return Icon(
      iconData,
      size: 50, // Set the icon size as desired
      color: iconColor,
    );
  }
}
