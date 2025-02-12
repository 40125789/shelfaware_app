import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UnreadMessagesService {
  Stream<int> getUnreadMessagesCount(String currentUserId) {
    if (currentUserId.isEmpty) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)  // Get chats involving the user
        .snapshots()
        .asyncMap((chatSnapshot) async {
      int totalUnreadCount = 0;

      for (var chatDoc in chatSnapshot.docs) {
        final chatId = chatDoc.id;
        
        final unreadMessages = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .where('receiverId', isEqualTo: currentUserId) // Only messages sent to this user
            .get();

        totalUnreadCount += unreadMessages.docs.length;
      }
      return totalUnreadCount;
    });
  }
}
