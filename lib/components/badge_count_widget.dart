import 'package:flutter/material.dart';

class Badge extends StatelessWidget {
  final int count;

  const Badge({required this.count, required int unreadCount, required VoidCallback onNotificationPressed});


  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 8,
      backgroundColor: Colors.red,
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

