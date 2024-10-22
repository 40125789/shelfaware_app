import 'package:flutter/material.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onLocationPressed;
  final VoidCallback onNotificationPressed;
  final VoidCallback onMessagePressed;

  const TopAppBar({
    Key? key,
    this.title = '',
    required this.onLocationPressed,
    required this.onNotificationPressed,
    required this.onMessagePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green,
      iconTheme: IconThemeData(color: Colors.grey[800]),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.location_on, color: Colors.grey[800]),
          onPressed: onLocationPressed,
        ),
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.grey[800]),
          onPressed: onNotificationPressed,
        ),
        IconButton(
          icon: Icon(Icons.message, color: Colors.grey[800]),
          onPressed: onMessagePressed,
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 10.0)),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}