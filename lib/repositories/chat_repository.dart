// This file contains the ChatRepository class, which is responsible for handling all chat-related data operations.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository({required FirebaseFirestore firebaseFirestore, required FirebaseAuth firebaseAuth})
      : _firestore = firebaseFirestore,
        _auth = firebaseAuth;

Future<void> sendMessage(
  String donationId,
  String messageContent,
  String receiverId,
  String donorEmail,
  String productName,
) async {
  try {
    // Safely handle potential null currentUser or currentUserEmail
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User is not logged in");
    }

    final String currentUserId = currentUser.uid;
    final String currentUserEmail = currentUser.email ?? 'Unknown';  // Handle null email

    final Timestamp timestamp = Timestamp.now();

    // Generate chatId using donationId and userIds
    String chatId = _generateChatId(donationId, currentUserId, receiverId);

    // Reference to the chat document
    final chatDocRef = _firestore.collection('chats').doc(chatId);

    // Initialize chat document if it doesn't exist
    final chatDoc = await chatDocRef.get();
    if (!chatDoc.exists) {
      // If the chat document doesn't exist, create it
      await chatDocRef.set({
        'participants': [currentUserId, receiverId],
        'lastMessage': messageContent,
        'lastMessageTimestamp': timestamp,
        'product': {
          'productName': productName,
          'donationId': donationId,
        },
      });
    }

    // Add the message to the messages subcollection
    await chatDocRef.collection('messages').add({
      'senderId': currentUserId,
      'senderEmail': currentUserEmail,
      'receiverEmail': donorEmail,
      'receiverId': receiverId,
      'message': messageContent,
      'timestamp': timestamp,
      'isRead': false,
    });

    // Update last message in the chat document
    await chatDocRef.update({
      'lastMessage': messageContent,
      'lastMessageTimestamp': timestamp,
    });
  } catch (e) {
    throw Exception("Failed to send message: $e");
  }
}


  // Helper method to generate a unique chatId for the donation
  String _generateChatId(String donationId, String donorId, String receiverId) {
    List<String> ids = [donationId, donorId, receiverId];
    ids.sort(); // Sort IDs to ensure chatId consistency
    return ids.join('_'); // Unique chatId per donation
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messagesSnapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Future<String> getReceiverProfileImage(String receiverId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(receiverId).get();
      return userDoc['profileImageUrl'] ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<void> updateDonationStatus(String donationId, String newStatus) async {
    try {
      await _firestore.collection('donations').doc(donationId).update({'status': newStatus});
    } catch (e) {
      throw Exception("Failed to update status: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}