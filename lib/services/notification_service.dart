import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';  // For navigation purposes


class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService(this.flutterLocalNotificationsPlugin);

  // Initialize local notifications plugin
  Future<void> initialize() async {
   const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@android:drawable/ic_dialog_info');
    final initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Method to send expiry notification
  Future<void> sendExpiryNotification(String productName, DateTime expiryDate) async {
    // Calculate the remaining days until expiry
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    String expiryMessage = '';

    // Provide a more specific message depending on how many days remain
    if (daysUntilExpiry < 0) {
      expiryMessage = '$productName has expired!';
    } else if (daysUntilExpiry == 0) {
      expiryMessage = '$productName expires today!';
    } else {
      expiryMessage = '$productName expires in $daysUntilExpiry days.';
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'expiry_notifications',
      'Expiry Notifications',
      channelDescription: 'Notifications for food items about to expire',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0, // notification ID
      'Food Expiry Alert', // Title of the notification
      expiryMessage, // Body of the notification
      platformChannelSpecifics,
    );
  }

  // Handle background messages (when app is in background or terminated)
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await _showNotification(flutterLocalNotificationsPlugin, message);
  }

  // Handle foreground messages (when the app is in the foreground)
  Future<void> firebaseMessageHandler(RemoteMessage message) async {
    await _showNotification(flutterLocalNotificationsPlugin, message);
  }

  // Show notification when an app notification is tapped
  static Future<void> _showNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    RemoteMessage message,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'expiry_notifications',
      'Expiry Notifications',
      channelDescription: 'Notifications for food items about to expire',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    // Extract product name and expiry date from the message payload
    final String productName = message.data['productName'] ?? 'Unknown product';
    final String expiryDateString = message.data['expiryDate'] ?? '';
    final DateTime expiryDate = DateTime.parse(expiryDateString);

    // Calculate the days until expiry
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    String expiryMessage = '';

    if (daysUntilExpiry < 0) {
      expiryMessage = '$productName has expired!';
    } else if (daysUntilExpiry == 0) {
      expiryMessage = '$productName expires today!';
    } else {
      expiryMessage = '$productName expires in $daysUntilExpiry days.';
    }

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0, // notification ID
      'Food Expiry Alert', // Title of the notification
      expiryMessage, // Body of the notification
      platformChannelSpecifics,
      payload: '$productName,$expiryDate',
    );
  }

  // Method to handle when notification is tapped
  void firebaseTapHandler(RemoteMessage message) async {
    // Example: Handle notification tap by navigating to a specific screen
    print("Tapped on notification: ${message.notification?.title}");

    // Extract relevant data from the notification payload
    final String productName = message.data['productName'] ?? 'Unknown product';
    final String expiryDateString = message.data['expiryDate'] ?? '';
    final DateTime expiryDate = DateTime.parse(expiryDateString);

// This method will be called when a notification is tapped
Future<void> selectNotification(String? payload) async {
  if (payload != null) {
    // You can parse the payload to get the product name and expiry date
    final parts = payload.split(',');
    final productName = parts[0];
    final expiryDateString = parts[1];
    final expiryDate = DateTime.parse(expiryDateString);

    // You can now navigate to a specific screen to show the expiring items
    print("Tapped on notification for: $productName, Expiry Date: $expiryDate");

    // Example navigation to a specific screen (you need to define your screen)
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ExpiryDetailsPage(productName: productName, expiryDate: expiryDate),
    //   ),
    // );
  }
}

  }
}
