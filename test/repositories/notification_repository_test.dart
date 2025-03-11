
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shelfaware_app/repositories/notification_repository.dart';


void main() {
  late NotificationRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    // Use FakeFirebaseFirestore instead of a mock
    fakeFirestore = FakeFirebaseFirestore();
    // For FirebaseAuth, use a mock from firebase_auth_mocks
    mockAuth = MockFirebaseAuth();
    repository = NotificationRepository(
        firestore: fakeFirestore, auth: mockAuth); // Pass dependencies here
  });

  group('NotificationRepository', () {
    test('fetchNotifications returns notifications for a user', () async {
      // Arrange: Add some notifications to fake Firestore for a user
      final userId = 'user123';
      await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'message': 'New notification',
        'timestamp': DateTime.now(),
      });

      // Act
      final result = await repository.fetchNotifications(userId);

      // Assert
      expect(result.isNotEmpty, true);
      expect(result.first['userId'], equals(userId));
      expect(result.first['message'], equals('New notification'));
    });

    test('fetchNotifications returns an empty list if no notifications exist',
        () async {
      // Arrange: Ensure no notifications for the user
      final userId = 'user123';

      // Act
      final result = await repository.fetchNotifications(userId);

      // Assert
      expect(result.isEmpty, true);
    });

    test('clearAllNotifications clears all notifications for a user', () async {
      // Arrange: Add some notifications to fake Firestore
      final userId = 'user123';
      await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'message': 'Notification to be cleared',
        'timestamp': DateTime.now(),
      });

      // Act
      await repository.clearAllNotifications(userId);

      // Assert
      final snapshot = await fakeFirestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      expect(snapshot.docs.isEmpty, true);
    });

    test('markAsRead marks a notification as read', () async {
      // Arrange: Add a notification to fake Firestore
      final notificationId = 'notif123';
      await fakeFirestore.collection('notifications').doc(notificationId).set({
        'message': 'New notification',
        'read': false,
        'timestamp': DateTime.now(),
      });

      // Act
      await repository.markAsRead(notificationId);

      // Assert
      final doc = await fakeFirestore
          .collection('notifications')
          .doc(notificationId)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['read'], true);
    });

    test(
        'getUnreadNotificationCount returns correct count of unread notifications',
        () async {
      // Arrange: Add some notifications to fake Firestore
      final userId = 'user123';
      await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'message': 'First unread notification',
        'read': false,
        'timestamp': DateTime.now(),
      });
      await fakeFirestore.collection('notifications').add({
        'userId': userId,
        'message': 'Second unread notification',
        'read': false,
        'timestamp': DateTime.now(),
      });

      // Act
      final result = await repository.getUnreadNotificationCount(userId).first;

      // Assert
      expect(result, 2);
    });
  });
}
