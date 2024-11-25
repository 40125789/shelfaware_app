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

Future<void> sendMessage(
  String donationId,
  String messageContent,
  String receiverId,
  String donorEmail,
  String productName,
) async {
  try {
    final String currentUser = FirebaseAuth.instance.currentUser!.uid;
    final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // Print values to check
    print("Donation ID: $donationId");
    print("Sender (currentUser): $currentUser");
    print("Receiver ID: $receiverId");

    // Generate chatId using donationId and userIds
    String chatId = _generateChatId(donationId, currentUser, receiverId);

    // Log the generated chatId for debugging
    print("Generated chatId: $chatId");

    // Reference to the chat document
    final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Initialize chat document if it doesn't exist
    final chatDoc = await chatDocRef.get();
    if (!chatDoc.exists) {
      // If the chat document doesn't exist, create it
      await chatDocRef.set({
        'participants': [currentUser, receiverId],
        'lastMessage': messageContent,
        'lastMessageTimestamp': timestamp,
        'product': {
          'productName': productName,
          'donationId': donationId,
        },
      });

      print("Chat document created for chatId: $chatId");
    }

    // Add the message to the messages subcollection
    await chatDocRef.collection('messages').add({
      'senderId': currentUser,
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

    print("Message sent successfully.");
  } catch (e) {
    print("Error sending message: $e");
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
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
