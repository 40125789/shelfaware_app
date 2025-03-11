import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shelfaware_app/services/chat_service.dart';
import 'package:shelfaware_app/repositories/chat_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockQuerySnapshot extends Mock implements QuerySnapshot {}

void main() {
  late ChatService chatService;
  late MockChatRepository mockChatRepository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirebaseFirestore;

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseFirestore = MockFirebaseFirestore();
    chatService = ChatService();
  });

  test('getUsersStream should return a stream of users', () {
    when(mockChatRepository.getUsersStream()).thenAnswer((_) => Stream.value([]));
    expect(chatService.getUsersStream(), isA<Stream<List<Map<String, dynamic>>>>());
  });

  test('sendMessage should call sendMessage on the repository', () async {
    await chatService.sendMessage('donationId', 'messageContent', 'receiverId', 'donorEmail', 'productName');
    verify(mockChatRepository.sendMessage('donationId', 'messageContent', 'receiverId', 'donorEmail', 'productName')).called(1);
  });
    when(mockChatRepository.getMessages('chatId')).thenAnswer((_) => Stream.value(MockQuerySnapshot()));
  test('getMessages should return a stream of messages', () {
    when(mockChatRepository.getMessages('chatId')).thenAnswer((_) => Stream.value(MockQuerySnapshot()));
    expect(chatService.getMessages('chatId'), isA<Stream<QuerySnapshot>>());
  });

  test('markMessagesAsRead should call markMessagesAsRead on the repository', () async {
    await chatService.markMessagesAsRead('chatId', 'userId');
    verify(mockChatRepository.markMessagesAsRead('chatId', 'userId')).called(1);
  });

  test('getReceiverProfileImage should return a profile image URL', () async {
    when(mockChatRepository.getReceiverProfileImage('receiverId')).thenAnswer((_) async => 'profileImageUrl');
    expect(await chatService.getReceiverProfileImage('receiverId'), 'profileImageUrl');
  });

  test('updateDonationStatus should call updateDonationStatus on the repository', () async {
    await chatService.updateDonationStatus('donationId', 'newStatus');
    verify(mockChatRepository.updateDonationStatus('donationId', 'newStatus')).called(1);
  });

  test('getChatId should return a sorted chat ID', () {
    expect(chatService.getChatId('donationId', 'userId', 'receiverId'), 'donationId_receiverId_userId');
  });
}