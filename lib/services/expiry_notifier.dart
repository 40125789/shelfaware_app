import 'package:shelfaware_app/services/notification_service.dart';

class ExpiryNotifier {
  final NotificationService _notificationService = NotificationService();

  ExpiryNotifier() {
    _notificationService.initialize();
  }

  // Method to check items for expiry within 1 day
  void checkExpiringItems(List<foodItems> foodItems) {
    final now = DateTime.now();

    for (var item in foodItems) {
      final difference = item.expiryDate.difference(now).inDays;
      if (difference == 1) {
        _notificationService.sendExpiryNotification(
          'Expiry Alert for ${item.name}',
          '${item.name} will expire tomorrow. Don\'t forget to use it!',
        );
      }
    }
  }
}
