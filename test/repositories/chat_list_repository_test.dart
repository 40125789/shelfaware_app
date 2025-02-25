import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/repositories/chat_list_repository.dart';


import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late ChatListRepository chatListRepository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();

    mockUser = MockUser(
      isAnonymous: false,
      uid: 'testUserId',
      email: 'testUserEmail',
    );

    mockAuth = MockFirebaseAuth(mockUser: mockUser);

    chatListRepository = ChatListRepository(
      firebaseFirestore: fakeFirestore,
      firebaseAuth: mockAuth,
    );
  });

  test('getChats should return a stream of chats for a user', () async {
    await fakeFirestore.collection('chats').add({
      'participants': ['testUserId', 'anotherUserId'],
      'lastMessageTimestamp': Timestamp.now(),
    });

    final stream = chatListRepository.getChats('testUserId', true);
    final snapshot = await stream.first;

    expect(snapshot.docs.length, 1);
    expect((snapshot.docs.first.data() as Map<String, dynamic>)['participants'], contains('testUserId'));
  });

  test('getProfileImageUrl should return the correct profile image URL', () async {
    await fakeFirestore.collection('users').doc('testReceiverId').set({
      'profileImageUrl': 'testProfileImageUrl',
    });

    final profileImageUrl = await chatListRepository.getProfileImageUrl('testReceiverId');
    expect(profileImageUrl, 'testProfileImageUrl');
  });

  test('getUserName should return the correct user name', () async {
    await fakeFirestore.collection('users').doc('testReceiverId').set({
      'firstName': 'Test Receiver',
    });

    final userName = await chatListRepository.getUserName('testReceiverId');
    expect(userName, 'Test Receiver');
  });

  test('getUnreadMessagesCount should return the correct count of unread messages', () async {
    final chatId = 'testChatId';

    await fakeFirestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': 'testReceiverId',
      'receiverId': 'testUserId',
      'message': 'Test message',
      'isRead': false,
    });

    await fakeFirestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': 'testReceiverId',
      'receiverId': 'testUserId',
      'message': 'Another test message',
      'isRead': false,
    });

    final unreadMessagesCount = await chatListRepository.getUnreadMessagesCount(chatId, 'testUserId');
    expect(unreadMessagesCount, 2);
  });
}
