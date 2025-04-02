import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/repositories/chat_repository.dart';


class ChatService {
  final ChatRepository _chatRepository = ChatRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  );

  Stream<User?> get userStream => FirebaseAuth.instance.authStateChanges();

  // Stream to fetch all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _chatRepository.getUsersStream();
  }

  Future<void> sendMessage(
    String donationId,
    String messageContent,
    String receiverId,
    String donorEmail,
    String productName,
  ) async {
    await _chatRepository.sendMessage(
      donationId,
      messageContent,
      receiverId,
      donorEmail,
      productName,
    );
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _chatRepository.getMessages(chatId);
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await _chatRepository.markMessagesAsRead(chatId, userId);
  }

  Future<String> getReceiverProfileImage(String receiverId) async {
    return await _chatRepository.getReceiverProfileImage(receiverId);
  }

  Future<String?> getDonationStatus(String donationId) async {
    return await _chatRepository.getDonationStatus(donationId);
  }



  String getChatId(String donationId, String userId, String receiverId) {
    List<String> ids = [donationId, userId, receiverId];
    ids.sort();
    return ids.join('_');
  }
}