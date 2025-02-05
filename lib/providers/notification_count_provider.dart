// notification_state.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationCountProvider = StateNotifierProvider<NotificationCountNotifier, int>(
  (ref) => NotificationCountNotifier(),
);

class NotificationCountNotifier extends StateNotifier<int> {
  NotificationCountNotifier() : super(0); // Initially, 0 unread notifications

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
