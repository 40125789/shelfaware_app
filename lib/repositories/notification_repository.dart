import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> notifications = [];

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    try {
      // Fetch notifications from Firestore
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      // Check if any notifications were returned
      if (snapshot.docs.isEmpty) {
        print('No notifications found.');
      }

      // Map the snapshot documents to a list of maps, including document ID
      List<Map<String, dynamic>> notifications = snapshot.docs.map((doc) {
        // Log document ID
        print('Document ID (Notification ID): ${doc.id}');

        // Get the data for the document
        Map<String, dynamic> notificationData =
            doc.data() as Map<String, dynamic>;

        // Add document ID as 'id' in the notification data
        notificationData['id'] = doc.id;

        // Log the notification data including the ID
        print('Notification Data with ID: $notificationData');

        return notificationData;
      }).toList();

      return notifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> clearAllNotifications(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<DocumentSnapshot> fetchChat(String chatId) async {
    try {
      return await _firestore.collection('chats').doc(chatId).get();
    } catch (e) {
      print('Error fetching chat: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot> fetchMessages(String chatId) async {
    try {
      return await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
    } catch (e) {
      print('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<String> fetchReceiverName(String receiverId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(receiverId).get();
      if (userDoc.exists) {
        var userData = userDoc.data();
        return (userData as Map<String, dynamic>)['firstName'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (error) {
      print("Error fetching receiver name: $error");
      return 'Unknown';
    }
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.length);
  }

  // Optionally, add a function to fetch specific notification by ID
  Future<Map<String, dynamic>?> getNotificationById(
      String notificationId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching notification: $e');
      return null;
    }
  }
}
