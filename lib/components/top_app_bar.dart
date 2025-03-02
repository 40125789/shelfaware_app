import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/pages/location_page.dart';
import 'package:shelfaware_app/providers/notification_count_provider.dart';



class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
final unreadCount = ref.watch(notificationCountProvider);
   

        return AppBar(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // Location Icon with Navigation to LocationPage
            IconButton(
              icon: Icon(Icons.location_on),
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
                  icon: Icon(Icons.notifications),
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
