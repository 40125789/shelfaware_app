import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/providers/notification_count_provider.dart';

class NotificationService {
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notification plugins
  Future<void> initializeNotifications(context) async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Set your app icon

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Handle foreground notifications (app is in the foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message.notification!.title, message.notification!.body, message.data['chatId']);
      }
    });

    // Get the new unread count 
    int newCount = await getUnreadNotificationCount(FirebaseAuth.instance.currentUser!.uid).first;
    context.read(notificationCountProvider.notifier).setUnreadCount(newCount);
    

    // Handle background notifications (app is in the background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        _handleNotificationTap(message.data);
      }
    });
  }

  // Show a local notification
  Future<void> _showLocalNotification(String? title, String? body, String chatId) async {
    // Define notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel_id', // channelId
      'Default Channel', // channelName
      channelDescription: 'This is the default channel', // channelDescription
      importance: Importance.high, // Set importance to high
      priority: Priority.high, // Set priority to high
      showWhen: false, // Do not show time when notification is shown
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidDetails);

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0,// Notification ID (this is a unique identifier for the notification)
      title, // Notification title
      body, // Notification body
      platformChannelSpecifics, // Notification details
      payload: chatId, // Optional payload for data
    );
  }

  // Handle notification tap (open the app or navigate to a screen)
  void _handleNotificationTap(Map<String, dynamic> data) {
    // Logic for handling notification tap, such as navigating to a screen
    print('Notification tapped! Data: $data');
  }

  // Fetch notifications by userId
  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    try {
      print('Fetching notifications for userId: $userId');
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications') // Collection name: 'notifications'
          .where('userId', isEqualTo: userId) // Filter by userId
          .orderBy('timestamp', descending: true) // Order by timestamp (descending)
          .get(); // Get the query snapshot

      // Convert the query snapshot to a list of maps
      return snapshot.docs.map((doc) {
       Map<String, dynamic> notification = doc.data() as Map<String, dynamic>;
      notification['notificationId'] = doc.id; // Add the document ID as 'notificationId'
      return notification;
    }).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return []; // Return empty list on error
    }
  }

  // Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    if (userId == null) return; // If userId is null, exit early

    final collection = FirebaseFirestore.instance.collection('notifications');
    final batch = FirebaseFirestore.instance.batch();

    // Query notifications that belong to the current user
    final querySnapshot = await collection.where('userId', isEqualTo: userId).get();

    // Add all notifications to the batch for deletion
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Commit the batch to delete all matching notifications
    await batch.commit();
  }

  // Get unread notification count for a user
  Stream<int> getUnreadNotificationCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false) // Filter by unread status
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  // Update the notification's read status in Firestore
  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({
      'read': true,
    });
  }

  // Filter notifications by type (e.g., 'message' or 'expiry')
  List<Map<String, dynamic>> filterByType(
      List<Map<String, dynamic>> notifications, String type) {
    return notifications
        .where((notification) => notification['type'] == type)
        .toList();
  }

  // Optionally, add a function to fetch specific notification by ID
  Future<Map<String, dynamic>?> getNotificationById(String notificationId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching notification: $e');
      return null;
    }
  }

  // Request permission for push notifications
  Future<void> requestNotificationPermission() async {
    await _firebaseMessaging.requestPermission();
  }

  // Get the device's FCM token
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Subscribe to a specific topic for notifications
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
