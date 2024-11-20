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
      String receiverId, String donorEmail, dynamic message, String productName, String chatId, String donatorId) async {
    try {
      final String currentUser = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email!;
      final Timestamp timestamp = Timestamp.now();

      // Fetch donor's details
      final donationDoc =
          await _firestore.collection('donations').doc(donationId).get();
      if (!donationDoc.exists) {
        throw Exception("Donation with ID $donationId does not exist.");
      }

      final donorId = donationDoc['donorId'];
      final donorEmail = donationDoc['donorEmail'];

      // Create the chat room ID
      List<String> ids = [currentUser, donorId];
      ids.sort();
      String chatId = ids.join('_');

      // Reference to the chat document
      final chatDocRef = _firestore.collection('chats').doc(chatId);

      // Initialize chat document if it doesn't exist
      final chatDoc = await chatDocRef.get();
      if (!chatDoc.exists) {
        await chatDocRef.set({
          'participants': [currentUser, donorId],
          'lastMessage': messageContent,
          'lastMessageTimestamp': timestamp,
          'product': {
            'productName': donationDoc['productName'],
            'expiryDate': donationDoc['expiryDate'],
          },
        });
      }

      // Add the message to the messages subcollection
      await chatDocRef.collection('messages').add({
        'senderId': currentUser,
        'senderEmail': currentUserEmail,
        'receiverEmail': donorEmail,
        'receiverId': donorId,
        'message': message,
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

  // Get messages for a specific chat room
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId, String receiverId, String message) {
    List<String> ids = [userId, otherUserId];
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
