import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatListRepository({required FirebaseFirestore firebaseFirestore, required FirebaseAuth firebaseAuth})
      : _firestore = firebaseFirestore,
        _auth = firebaseAuth;

  Stream<QuerySnapshot> getChats(String userId, bool isDescending) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: isDescending)
        .snapshots();
  }

  Future<String> getProfileImageUrl(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['profileImageUrl'] ?? ''; // Default to empty if no image URL found
    } catch (e) {
      return ''; // Return empty if there's an error fetching the image
    }
  }

  Future<String> getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['firstName'] ?? 'Unknown User'; // Default if no name found
    } catch (e) {
      return 'Unknown User'; // Return fallback if there's an error
    }
  }

  Future<int> getUnreadMessagesCount(String chatId, String currentUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('receiverId', isEqualTo: currentUserId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      return 0; // Return 0 if there's an error
    }
  }
}