import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelfaware_app/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  // Stream to fetch all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

Future<void> sendMessage(String donationId, String messageContent,
    String receiverId, String donorEmail, String productName, String chatId, String donationName, dynamic messagecontent, String donorName) async {
  try {
    final String currentUser = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // Create the chat room ID based on donationId, current user, and donor
    List<String> ids = [donationId, currentUser, receiverId];
    ids.sort();
    chatId = ids.join('_'); // Ensures chatId is unique per donation and users

    // Fetch the donation document
    final donationDoc = await _firestore.collection('donations').doc(donationId).get();

    // Reference to the chat document
    final chatDocRef = _firestore.collection('chats').doc(chatId);

    // Initialize chat document if it doesn't exist
    final chatDoc = await chatDocRef.get();
    if (!chatDoc.exists) {
      await chatDocRef.set({
        'participants': [currentUser, receiverId],
        'lastMessage': messageContent,
        'lastMessageTimestamp': timestamp,
        'product': {
          'ProductName': productName,
        },
        'donationId': donationId,
      });
      print("Chat document created for chatId: $chatId");
    }

    // Add the message to the messages subcollection
    await chatDocRef.collection('messages').add({
      'senderId': currentUser,
      'senderEmail': currentUserEmail,
      'receiverEmail': donorEmail, // Correcting the receiver's email
      'receiverId': receiverId,   // Correcting the receiver's ID
      'message': messageContent,
      'timestamp': timestamp,
      'isRead': false,
    });

    // Update last message in the chat document
    await chatDocRef.update({
      'lastMessage': messageContent,
      'lastMessageTimestamp': timestamp,
    });

    print("Message sent successfully.");
  } catch (e) {
    print("Error sending message: $e");
    throw Exception("Failed to send message: $e");
  }
}


  Stream<QuerySnapshot> getMessages(String userId, String otherUserId, String donationId) {
  // Create a unique chatId based on user IDs and donationId
  List<String> ids = [userId, otherUserId, donationId];
  ids.sort();
  String chatId = ids.join('_');

  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots();
}

}
