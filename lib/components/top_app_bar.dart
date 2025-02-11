import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/controllers/expiring_items_controller.dart'; // Import the controller // Import the ExpiringItemsScreen
import 'package:shelfaware_app/services/data_fetcher.dart'; // Import the DataFetcher
import 'package:shelfaware_app/models/food_item.dart'; // Import the FoodItem model
import 'package:shelfaware_app/services/notification_service.dart'; 
import 'package:shelfaware_app/pages/location_page.dart';


class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onNotificationPressed;
  final String userId;

  const TopAppBar({
    Key? key,
    this.title = '',
    required this.onNotificationPressed,
    required this.userId, required Null Function() onLocationPressed, required Null Function(int index) onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadNotificationCount(userId), // Call the service's stream method
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while fetching data
          return AppBar(
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
          title: Text(title),
          actions: [
            // Location Icon with Navigation to LocationPage
            IconButton(
              icon: Icon(Icons.location_on, color: Colors.grey[800]),
              onPressed: () async {
                // Navigate to LocationPage to let the user change their location
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LocationPage()),
                );
              },
            ),
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
