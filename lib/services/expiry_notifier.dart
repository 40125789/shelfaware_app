
import 'package:shelfaware_app/services/notification_service.dart';
import 'package:shelfaware_app/models/food_item.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ExpiryNotifier {
  // Declare NotificationService with the necessary FlutterLocalNotificationsPlugin
  final NotificationService _notificationService;

  ExpiryNotifier(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin)
      : _notificationService = NotificationService(flutterLocalNotificationsPlugin) {
    _notificationService.initialize();
  }

  // Method to check items for expiry within 1 day and send notifications
  void checkExpiringItems(List<FoodItem> foodItems) {
    final now = DateTime.now();

    for (var item in foodItems) {
      final difference = item.expiryDate.difference(now).inDays;

      // Check if the item expires tomorrow
      if (difference == 1) {
        // Send notification for expiring food item with product name and expiration info
        _notificationService.sendExpiryNotification(
          item.name, // Pass the item name
          item.expiryDate, // Pass the expiry date to format the message
        );
      }
    }
  }

  // Method to get a list of expiring items for the next day
  Future<List<String>> getExpiringItems(List<FoodItem> foodItems) async {
    List<String> expiringItems = [];
    final now = DateTime.now();

    // Iterate through the list of food items and check expiry dates
    for (var item in foodItems) {
      final difference = item.expiryDate.difference(now).inDays;

      // If an item will expire tomorrow, add it to the list
      if (difference == 1) {
        expiringItems.add('${item.name} will expire tomorrow!');
      }
    }

    return expiringItems;
  }
}
