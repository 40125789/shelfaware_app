import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shelfaware_app/repositories/unread_messages_repository.dart';

void main() {
  late UnreadMessagesRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    // For FirebaseAuth, you can use a mock from firebase_auth_mocks
    mockAuth = MockFirebaseAuth();
    repository =
        UnreadMessagesRepository(firestore: fakeFirestore, auth: mockAuth);
  });

  test('getChats should return chats where the user is a participant',
      () async {
    // Arrange
    final currentUserId = 'user123';
    await fakeFirestore.collection('chats').add({
      'participants': ['user123', 'user456']
    });
    await fakeFirestore.collection('chats').add({
      'participants': ['user789', 'user456']
    });

    // Act
    final chatStream = repository.getChats(currentUserId);
    final chats = await chatStream.first;

    // Assert
    expect(chats.docs.length, 1);
    expect((chats.docs.first.data() as Map<String, dynamic>)['participants'],
        contains(currentUserId));
  });

  test(
      'getUnreadMessagesCount should return the correct count of unread messages',
      () async {
    // Arrange
    final chatId = 'chat123';
    final currentUserId = 'user123';

    await fakeFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'isRead': false,
      'receiverId': currentUserId,
    });

    await fakeFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'isRead': true,
      'receiverId': currentUserId,
    });

    await fakeFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'isRead': false,
      'receiverId': 'user456', // Different user
    });

    // Act
    final unreadCount =
        await repository.getUnreadMessagesCount(chatId, currentUserId);

    // Assert
    expect(unreadCount, equals(1));
  });

  test(
      'getUnreadMessagesCount should return zero if there are no unread messages',
      () async {
    // Arrange
    final chatId = 'chat123';
    final currentUserId = 'user123';

    await fakeFirestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'isRead': true,
      'receiverId': currentUserId,
    });

    // Act
    final unreadCount =
        await repository.getUnreadMessagesCount(chatId, currentUserId);

    // Assert
    expect(unreadCount, equals(0));
  });
}
