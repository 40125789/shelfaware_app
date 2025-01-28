import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<String> _fetchReceiverName(String receiverId) async {
    try {
      // Fetch user data based on receiverId
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data();
        return (userData as Map<String, dynamic>)['firstName'] ??
            'Unknown'; // Return 'Unknown' if the name is missing
      } else {
        return 'Unknown'; // Return 'Unknown' if the user doesn't exist
      }
    } catch (error) {
      print("Error fetching donor name: $error");
      return 'Unknown'; // Return 'Unknown' in case of an error
    }
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
              String notificationId = notification['notificationId'];
              if (notification['type'] == 'message') {
                String chatId =
                    notification['chatId']; // Assuming 'chatId' exists

                // Check if chatId is null or empty before navigating
                if (chatId != null && chatId.isNotEmpty) {
                  try {
                    // Step 1: Mark notification as read and refresh UI
                    await NotificationService().markAsRead(
                        notificationId); // Using the document ID directly

                    // Step 2: Fetch the chat document using chatId
                    DocumentSnapshot chatSnapshot = await FirebaseFirestore
                        .instance
                        .collection('chats')
                        .doc(chatId)
                        .get();

                    if (chatSnapshot.exists) {
                      var chatData = chatSnapshot.data();
                      print("Chat data: $chatData");

                      if (chatData != null) {
                        // Fetch participants list
                        List<String> participants = List<String>.from(
                            (chatData as Map<String, dynamic>)['participants']);

                        // Dynamically determine receiverId based on the logged-in user
                        String loggedInUserId =
                            FirebaseAuth.instance.currentUser?.uid ??
                                ''; // Assuming Firebase Auth is used
                        String receiverId = participants.firstWhere(
                            (id) => id != loggedInUserId,
                            orElse: () => ''); // Get the receiverId

                        // Fetch product details
                        String productId =
                            chatData['product']?['donationId'] ?? '';
                        String productName =
                            chatData['product']?['productName'] ?? '';
                        String userId = chatData['userId'] ?? '';

                        // Step 3: Fetch the most recent message in the messages subcollection
                        QuerySnapshot messagesSnapshot = await FirebaseFirestore
                            .instance
                            .collection('chats')
                            .doc(chatId)
                            .collection('messages')
                            .orderBy('timestamp', descending: true)
                            .limit(1)
                            .get();

                        String lastMessage = '';
                        String senderEmail = '';
                        String receiverEmail = '';

                        if (messagesSnapshot.docs.isNotEmpty) {
                          var lastMessageData =
                              messagesSnapshot.docs.first.data();
                          lastMessage = (lastMessageData
                                  as Map<String, dynamic>)['message'] ??
                              '';
                          senderEmail = lastMessageData?['senderEmail'] ?? '';
                          receiverEmail =
                              lastMessageData?['receiverEmail'] ?? '';
                        }

                        // Step 4: Fetch the receiver's name (donor name) from the users collection
                        String donorName = await _fetchReceiverName(receiverId);

                        // Refresh the UI by calling setState
                        setState(() {
                          notification['read'] =
                              true; // Assuming 'notification' is a reference to the specific notification
                        });

                        // Step 5: Navigate to the ChatPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatId: chatId,
                              receiverEmail: receiverEmail,
                              receiverId: receiverId,
                              donationId: productId,
                              userId: userId,
                              donationName: productName,
                              donorName: donorName,
                            ),
                          ),
                        );
                      }
                    } else {
                      // Handle the case where chat document doesn't exist
                      print("Chat document does not exist for chatId: $chatId");
                    }
                  } catch (e) {
                    print("Error fetching chat and message data: $e");
                  }
                } else {
                  // Handle the case where chatId is missing or empty
                  print("Error: Missing or empty chatId for notification.");
                }
              }
            },
            child: ListTile(
              title: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    notification['title'],
                    style: TextStyle(
                      fontWeight: notification['read'] == false
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
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
                  Text(
                    notification['body'],
                    style: TextStyle(
                      fontWeight: notification['read'] == false
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
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
