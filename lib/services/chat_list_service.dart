import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/repositories/chat_list_repository.dart';

class ChatListService {
  final ChatListRepository _chatListRepository;

  ChatListService(this._chatListRepository);

  Stream<QuerySnapshot> getChats(String userId, bool isDescending) {
    return _chatListRepository.getChats(userId, isDescending);
  }

  Future<String> getProfileImageUrl(String userId) {
    return _chatListRepository.getProfileImageUrl(userId);
  }

  Future<String> getUserName(String userId) {
    return _chatListRepository.getUserName(userId);
  }

  Future<int> getUnreadMessagesCount(String chatId, String currentUserId) {
    return _chatListRepository.getUnreadMessagesCount(chatId, currentUserId);
  }
}