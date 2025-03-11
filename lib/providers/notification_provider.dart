import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/repositories/notification_repository.dart';
import 'package:shelfaware_app/services/notification_service.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';


// 1. NotificationRepository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  return NotificationRepository(firestore: firestore, auth: auth);
});

// 2. NotificationService Provider (Depends on NotificationRepository)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return NotificationService(notificationRepository);
});

// 3. Notifications List Provider
final notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  final authState = ref.watch(authStateProvider); // Ensure you handle auth state here

  return authState.when(
    data: (user) {
      if (user != null) {
        return notificationService.fetchNotifications(user.uid);
      } else {
        return []; // Return empty list if user is null
      }
    },
    loading: () => [], // Return empty list during loading
    error: (_, __) => [], // Return empty list in case of an error
  );
});

// 4. Unread Notification Count Provider
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return notificationService.getUnreadNotificationCount(user.uid);
      } else {
        return Stream.value(0); // Return stream with value 0 if no user is logged in
      }
    },
    loading: () => Stream.value(0), // Return stream with value 0 during loading
    error: (_, __) => Stream.value(0), // Return stream with value 0 on error
  );
});

// 5. Notification by ID Provider (Fetches notification by ID)
final notificationByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, notificationId) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getNotificationById(notificationId);
});
