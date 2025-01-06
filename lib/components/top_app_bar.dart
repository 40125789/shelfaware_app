import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/controllers/expiring_items_controller.dart'; // Import the controller
import 'package:shelfaware_app/pages/expiring_items_page.dart'; // Import the ExpiringItemsScreen
import 'package:shelfaware_app/services/data_fetcher.dart'; // Import the DataFetcher
import 'package:shelfaware_app/models/food_item.dart'; // Import the FoodItem model
import 'package:shelfaware_app/pages/expiring_items_page.dart';
import 'package:shelfaware_app/services/notification_service.dart'; // Import the ExpiringItemsScreen

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onLocationPressed;
  final VoidCallback onNotificationPressed;
  final String userId;

  const TopAppBar({
    Key? key,
    this.title = '',
    required this.onLocationPressed,
    required this.onNotificationPressed,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadNotificationCount(userId), // Call the service's stream method
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while fetching data
          return AppBar(
            backgroundColor: Colors.green,
            title: Text(title),
            actions: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ],
          );
        }

        // If data is available, set unread count
        int unreadCount = snapshot.data ?? 0;

        return AppBar(
          backgroundColor: Colors.green,
          title: Text(title),
          actions: [
            // Notification Icon with Badge
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.grey[800]),
                  onPressed: onNotificationPressed, 
                ),
                if (unreadCount > 0) // Show badge if there are unread notifications
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
                        '$unreadCount',
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
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
