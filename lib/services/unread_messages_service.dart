
import 'package:shelfaware_app/repositories/unread_messages_repository.dart';

class UnreadMessagesService {
  final UnreadMessagesRepository _repository;

  UnreadMessagesService(this._repository);

  Stream<int> getUnreadMessagesCount(String currentUserId) {
    if (currentUserId.isEmpty) return Stream.value(0);

    return _repository.getChats(currentUserId).asyncMap((chatSnapshot) async {
      int totalUnreadCount = 0;

      for (var chatDoc in chatSnapshot.docs) {
        final chatId = chatDoc.id;
        final unreadCount = await _repository.getUnreadMessagesCount(chatId, currentUserId);
        totalUnreadCount += unreadCount;
      }
      return totalUnreadCount;
    });
  }
}