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

    if (daysDifference < 0) {
      iconData = Icons.error;
      iconColor = Colors.red[700]!;
    } else if (daysDifference <= 5) {
      iconData = Icons.warning;
      iconColor = Colors.orange[700]!;
    } else {
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
