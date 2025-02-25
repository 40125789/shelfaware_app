import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/state/notification_state.dart';
import 'package:shelfaware_app/services/notification_service.dart';

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService notificationService;
  final String userId;

  NotificationNotifier({
    required this.notificationService,
    required this.userId,
  }) : super(NotificationState(notifications: [])) {
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      state = state.copyWith(isLoading: true);
      final notifications = await notificationService.fetchNotifications(userId);
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await notificationService.clearAllNotifications(userId);
      state = state.copyWith(notifications: []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await notificationService.markAsRead(notificationId);
      state = state.copyWith(
        notifications: state.notifications.map((notification) {
          if (notification['id'] == notificationId) {
            return {...notification, 'read': true};
          }
          return notification;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
