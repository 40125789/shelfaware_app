import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/controllers/expiring_items_controller.dart'; // Import the controller
import 'package:shelfaware_app/pages/expiring_items_page.dart'; // Import the ExpiringItemsScreen
import 'package:shelfaware_app/services/data_fetcher.dart'; // Import the DataFetcher
import 'package:shelfaware_app/models/food_item.dart'; // Import the FoodItem model
import 'package:shelfaware_app/pages/expiring_items_page.dart'; // Import the ExpiringItemsScreen

// TopAppBar widget to display the app bar with title and actions

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onLocationPressed;
  final VoidCallback onNotificationPressed;
  final int expiringItemCount;

  const TopAppBar({
    Key? key,
    this.title = '',
    required this.onLocationPressed,
    required this.onNotificationPressed,
    required this.expiringItemCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access the expiring and expired item counts
    final expiringSoonItemCount =
        context.watch<ExpiringItemsController>().expiringSoonItems.length;
    final expiredItemCount =
        context.watch<ExpiringItemsController>().expiredItems.length;

    // Total count of expiring items
    final totalExpiringItems = expiringSoonItemCount + expiredItemCount;

    return AppBar(
      backgroundColor: Colors.green,
      iconTheme: IconThemeData(color: Colors.grey[800]),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        // Location Button
        IconButton(
          icon: Icon(Icons.location_on, color: Colors.grey[800]),
          onPressed: onLocationPressed,
        ),

        // Notification Button with Badge
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.grey[800]),
              onPressed: () {
                // Navigate to the notifications screen when the icon is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpiringItemsScreen(),
                  ),
                );
              },
            ),
            if (totalExpiringItems >
                0) // Show badge if there are expiring or expired items
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$totalExpiringItems',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
