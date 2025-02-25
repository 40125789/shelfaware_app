// notification_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'package:shelfaware_app/providers/notification_provider.dart';
import 'package:shelfaware_app/services/notification_service.dart';

final notificationCountProvider = StateNotifierProvider<NotificationCountNotifier, int>(
  (ref) {
    final authState = ref.watch(authStateProvider).value;
    // If no user is logged in, return a notifier with default state (0) and an empty userId.
    if (authState == null) {
      return NotificationCountNotifier(
        notificationService: ref.watch(notificationServiceProvider),
        userId: '',
      );
    }
    final userId = authState.uid;
    final notificationService = ref.watch(notificationServiceProvider);
    return NotificationCountNotifier(
      notificationService: notificationService,
      userId: userId,
    );
  },
);

class NotificationCountNotifier extends StateNotifier<int> {
  final NotificationService notificationService;
  final String userId;

  NotificationCountNotifier({
    required this.notificationService,
    required this.userId,
  }) : super(0) {
    // Only fetch notifications if we have a valid userId.
    if (userId.isNotEmpty) {
      _fetchUnreadNotificationCount();
    }
  }

  Future<void> _fetchUnreadNotificationCount() async {
    // Listen for updates from the notification service.
    notificationService.getUnreadNotificationCount(userId).listen((count) {
      state = count;
    });
  }

  void setUnreadCount(int count) {
    state = count;
  }

  void incrementCount() {
    state++;
  }

  void decrementCount() {
    if (state > 0) state--;
  }
}
