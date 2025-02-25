import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/repositories/chat_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late ChatRepository chatRepository;
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

  chatRepository = ChatRepository(
    firebaseFirestore: fakeFirestore,
    firebaseAuth: mockAuth,
  );
});


  test('sendMessage should send a message and update chat document', () async {
    await chatRepository.sendMessage(
      'testDonationId',
      'testMessageContent',
      'testReceiverId',
      'testDonorEmail',
      'testProductName',
    );

    final chatDoc = await fakeFirestore.collection('chats').doc('testDonationId').get();
    expect(chatDoc.exists, true);

    final chatData = chatDoc.data()!;
    expect(chatData['participants'], containsAll(['testUserId', 'testReceiverId']));
    expect(chatData['lastMessage'], 'testMessageContent');
    expect(chatData['lastMessageTimestamp'], isNotNull);
    expect(chatData['product'], isA<Map<String, dynamic>>());
    expect(chatData['product']['productName'], 'testProductName');
    expect(chatData['product']['donationId'], 'testDonationId');

    final messagesCollection = await fakeFirestore
        .collection('chats')
        .doc('testDonationId')
        .collection('messages')
        .get();

    expect(messagesCollection.docs.length, 1);
    expect(messagesCollection.docs.first.data(), containsPair('message', 'testMessageContent'));
    expect(messagesCollection.docs.first.data()['timestamp'], isNotNull);
  });

  test('getMessages should return a stream of messages', () {
    final stream = chatRepository.getMessages('testChatId');
    expect(stream, isA<Stream<QuerySnapshot<Map<String, dynamic>>>>());
  });

  test('markMessagesAsRead should update unread messages to read', () async {
    await fakeFirestore
        .collection('chats')
        .doc('testChatId')
        .collection('messages')
        .add({
      'senderId': 'testUserId',
      'message': 'Hello',
      'isRead': false,
    });

    await chatRepository.markMessagesAsRead('testChatId', 'testUserId');

    final messagesCollection = await fakeFirestore
        .collection('chats')
        .doc('testChatId')
        .collection('messages')
        .where('isRead', isEqualTo: true)
        .get();

    expect(messagesCollection.docs.length, 1);
  });

  test('getReceiverProfileImage should return profile image URL', () async {
    await fakeFirestore.collection('users').doc('testReceiverId').set({
      'profileImageUrl': 'testProfileImageUrl',
    });

    await Future.delayed(Duration(milliseconds: 100));

    final profileImageUrl = await chatRepository.getReceiverProfileImage('testReceiverId');
    expect(profileImageUrl, 'testProfileImageUrl');
  });

  test('updateDonationStatus should update the status of a donation', () async {
    await fakeFirestore.collection('donations').doc('testDonationId').set({
      'status': 'oldStatus',
    });

    await chatRepository.updateDonationStatus('testDonationId', 'newStatus');

    final donationDoc = await fakeFirestore.collection('donations').doc('testDonationId').get();
    expect(donationDoc.data()?['status'], 'newStatus');
  });

  test('getUsersStream should return a stream of users', () {
    final stream = chatRepository.getUsersStream();
    expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
  });
}
