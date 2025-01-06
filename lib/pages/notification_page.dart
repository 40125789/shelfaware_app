import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/services/notification_service.dart';

// Adjust path as per your project structure

class NotificationPage extends StatefulWidget {
  final String userId;

  const NotificationPage({Key? key, required this.userId}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Function to fetch notifications from the service
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    return await NotificationService().fetchNotifications(widget.userId);
  }

  // Function to clear all notifications
  Future<void> clearAllNotifications() async {
    await NotificationService().clearAllNotifications(widget.userId);
  }

  // Filter notifications by type
  List<Map<String, dynamic>> filterByType(
      List<Map<String, dynamic>> notifications, String type) {
    return notifications
        .where((notification) => notification['type'] == type)
        .toList();
  }

  // Function to show confirmation dialog before clearing all notifications
  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete All Notifications'),
          content: Text(
              'Are you sure you want to delete all notifications? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                try {
                  await clearAllNotifications(); // Call the function to clear notifications
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All notifications cleared')),
                  );
                  setState(() {}); // Refresh the UI
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to clear notifications: $e')),
                  );
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>( 
      future: fetchNotifications(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Notifications')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Notifications')),
            body: Center(child: Text('Error fetching notifications')),
          );
        }

        final notifications = snapshot.data ?? [];
        final expiryNotifications = filterByType(notifications, 'expiry');
        final messageNotifications = filterByType(notifications, 'message');

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Notifications'),
              backgroundColor: Colors.green,
              actions: [
                TextButton(
                  onPressed: () async {
                    await _showDeleteConfirmationDialog(context);
                  },
                  child: Text(
                    'CLEAR',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Expiry Dates'),
                  Tab(text: 'Messages'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildNotificationList(expiryNotifications),
                _buildNotificationList(messageNotifications),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build the notification list
  Widget _buildNotificationList(List<Map<String, dynamic>> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No notifications'),
        ),
      );
    }

    return ListView(
      children: notifications.map((notification) {
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: InkWell(
            onTap: () async {
              String notificationId = notification['id']; // Assuming 'id' exists
              await NotificationService()
                  .markAsRead(notificationId); // Mark as read

              if (notification['type'] == 'message') {
                // Navigate to chat screen for message notification
                String chatId = notification['chatId']; // Assuming 'chatId' exists
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(chatId: chatId, receiverEmail: notification['receiverEmail'], receiverId: notification['receiverId'],  donationId: '', userId: '', donationName: '', donorName: '',), // Pass the chatId to the chat screen
                  ),
                );
              }

              setState(() {}); // Refresh UI after marking as read
            },
            child: ListTile(
              title: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(notification['title']),
                  if (notification['read'] == false)
                    Positioned(
                      right: -20,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['body']),
                  SizedBox(height: 4),
                  Text(
                    _formatTimestamp(notification['timestamp']),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Helper function to format the timestamp
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
