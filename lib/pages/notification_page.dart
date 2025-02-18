import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/pages/my_donations_page.dart';
import 'package:shelfaware_app/utils/notification_date_utils.dart'; // Import the utility file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'package:shelfaware_app/providers/notification_provider.dart';



class NotificationPage extends ConsumerWidget {
  const NotificationPage({Key? key}) : super(key: key);

  Future<void> _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete All Notifications'),
          content: Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final userId = ref.read(authStateProvider).value!.uid;
                  await ref.read(notificationServiceProvider).clearAllNotifications(userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All notifications cleared')),
                  );
                  ref.refresh(notificationsProvider);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to clear notifications: $e')),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsyncValue = ref.watch(notificationsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
          actions: [
            TextButton(
              onPressed: () async {
                await _showDeleteConfirmationDialog(context, ref);
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
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: notificationsAsyncValue.when(
          data: (notifications) {
            return TabBarView(
              children: [
                _buildNotificationList(context, filterByType(notifications, 'expiry'), ref),
                _buildNotificationList(context, filterByType(notifications, 'message'), ref),
                _buildNotificationList(context, filterByType(notifications, 'request'), ref),
              ],
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> filterByType(List<Map<String, dynamic>> notifications, String type) {
    return notifications.where((notification) => notification['type'] == type).toList();
  }

  Widget _buildNotificationList(BuildContext context, List<Map<String, dynamic>> notifications, WidgetRef ref) {
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
              try {
                print("Notification: $notification");  // Debugging line
                String? notificationId = notification['id'];
                print("Notification ID: $notificationId");  // Debugging line
                if (notificationId == null) return;

                final notificationDetails = await ref.read(notificationByIdProvider(notificationId).future);
                if (notificationDetails == null) return;

                if (notificationDetails['type'] == 'message') {
                  String? chatId = notificationDetails['chatId'];
                  if (chatId != null && chatId.isNotEmpty) {
                    await ref.read(notificationServiceProvider).markAsRead(notificationId);
                    ref.refresh(notificationsProvider); // Refresh notifications

                    DocumentSnapshot chatSnapshot = await ref.read(notificationServiceProvider).fetchChat(chatId);
                    if (chatSnapshot.exists) {
                      var chatData = chatSnapshot.data() as Map<String, dynamic>?;
                      if (chatData == null) return;

                      List<String> participants = List<String>.from(chatData['participants'] ?? []);
                      String loggedInUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                      String receiverId = participants.firstWhere((id) => id != loggedInUserId, orElse: () => '');

                      String productId = chatData['product']?['donationId'] ?? '';
                      String productName = chatData['product']?['productName'] ?? '';
                      String userId = chatData['userId'] ?? '';

                      QuerySnapshot messagesSnapshot = await ref.read(notificationServiceProvider).fetchMessages(chatId);

                      String lastMessage = '';
                      String senderEmail = '';
                      String receiverEmail = '';

                      if (messagesSnapshot.docs.isNotEmpty) {
                        var lastMessageData = messagesSnapshot.docs.first.data() as Map<String, dynamic>?;
                        if (lastMessageData != null) {
                          lastMessage = lastMessageData['message'] ?? '';
                          senderEmail = lastMessageData['senderEmail'] ?? '';
                          receiverEmail = lastMessageData['receiverEmail'] ?? '';
                        }
                      }

                      String donorName = await ref.read(notificationServiceProvider).fetchReceiverName(receiverId);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverEmail: receiverEmail,
                            receiverId: receiverId,
                            donationId: productId,
                            userId: userId,
                            donationName: productName,
                            donorName: donorName,
                            chatId: chatId,
                          ),
                        ),
                      );
                    }
                  }
                } else if (notificationDetails['type'] == 'request') {
                  if (notificationId.isNotEmpty) {
                    await ref.read(notificationServiceProvider).markAsRead(notificationId);
                    ref.refresh(notificationsProvider); // Refresh notifications
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyDonationsPage(userId: FirebaseAuth.instance.currentUser!.uid),
                      ),
                    );
                  }
                }
              } catch (e) {
                print("Error in onTap: $e");
              }
            },
            child: ListTile(
              title: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    notification['title'] ?? '',
                    style: TextStyle(
                      fontWeight: notification['read'] == false ? FontWeight.bold : FontWeight.normal,
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
                    notification['body'] ?? '',
                    style: TextStyle(
                      fontWeight: notification['read'] == false ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    NotificationDateUtils.formatTimestamp(notification['timestamp']),
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
}