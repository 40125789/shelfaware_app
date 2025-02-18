import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shelfaware_app/providers/notification_count_provider.dart';
import 'package:shelfaware_app/repositories/notification_repository.dart';


class NotificationService {
  final NotificationRepository _notificationRepository;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  NotificationService(this._notificationRepository);

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) {
    return _notificationRepository.fetchNotifications(userId);
  }

  Future<void> clearAllNotifications(String userId) {
    return _notificationRepository.clearAllNotifications(userId);
  }

  Future<void> markAsRead(String notificationId) {
    return _notificationRepository.markAsRead(notificationId);
  }

  Future<DocumentSnapshot> fetchChat(String chatId) {
    return _notificationRepository.fetchChat(chatId);
  }

  Future<QuerySnapshot> fetchMessages(String chatId) {
    return _notificationRepository.fetchMessages(chatId);
  }

  Future<String> fetchReceiverName(String receiverId) {
    return _notificationRepository.fetchReceiverName(receiverId);
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _notificationRepository.getUnreadNotificationCount(userId);
  }

  Future<Map<String, dynamic>?> getNotificationById(String notificationId) {
    return _notificationRepository.getNotificationById(notificationId);
  }

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
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel_id', 
      'Default Channel', 
      channelDescription: 'This is the default channel', 
      importance: Importance.high, 
      priority: Priority.high, 
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, 
      title, 
      body, 
      platformChannelSpecifics, 
      payload: chatId, 
    );
  }

  // Handle notification tap (open the app or navigate to a screen)
  void _handleNotificationTap(Map<String, dynamic> data) {
    print('Notification tapped! Data: $data');
    // Add logic to handle navigation based on data
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