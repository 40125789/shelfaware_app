import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationHandler {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final BuildContext context;

  NotificationHandler({required this.context});

  // Initialize notification handlers
  Future<void> initialize() async {
    // Handle notifications when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground: ${message.data}');
      _handleNotificationTap(message);
    });

    // Handle when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background: ${message.data}');
      _handleNotificationTap(message);
    });

    // Handle background notifications
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  // Background notification handler when the app is terminated or in the background
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    print('Handling background message: ${message.data}');
    // Handle background logic, if needed
  }

  // Handle the notification tap logic
  void _handleNotificationTap(RemoteMessage message) {
    if (message.data['chatId'] != null) {
      final chatId = message.data['chatId'];
      _navigateToChat(chatId);
    }
  }

  // Navigate to the specific chat screen
  void _navigateToChat(String chatId) {
    Navigator.pushNamed(context, '/chat', arguments: chatId);
  }
}
