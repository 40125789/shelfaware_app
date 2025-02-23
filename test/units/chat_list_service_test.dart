import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelfaware_app/repositories/chat_list_repository.dart';
import 'package:shelfaware_app/services/chat_list_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 // Import the generated mock file

class MockChatListRepositoryCustom extends Mock implements ChatListRepository {}

@GenerateMocks([ChatListRepository], customMocks: [MockSpec<ChatListRepository>(as: #MockChatListRepositoryCustom)])
void main() {
    late ChatListService chatListService;
    late MockChatListRepositoryCustom mockChatListRepository;
    setUp(() {
      mockChatListRepository = MockChatListRepositoryCustom();
      chatListService = ChatListService(mockChatListRepository);
    });

    group('ChatListService', () {
      test('getChats returns a stream of QuerySnapshot', () {
        final userId = 'testUserId';
        final isDescending = true;
        final mockStream = Stream<QuerySnapshot<Object?>>.empty();
        when(mockChatListRepository.getChats(userId, isDescending))
            .thenAnswer((_) => mockStream);

        final result = chatListService.getChats(userId, isDescending);

        expect(result, mockStream);
        verify(mockChatListRepository.getChats(userId, isDescending)).called(1);
      });

      test('getProfileImageUrl returns a profile image URL', () async {
        final userId = 'testUserId';
        final mockUrl = 'http://example.com/profile.jpg';

        when(mockChatListRepository.getProfileImageUrl(userId))
            .thenAnswer((_) => Future.value(mockUrl));

        final result = await chatListService.getProfileImageUrl(userId);

        expect(result, mockUrl);
        verify(mockChatListRepository.getProfileImageUrl(userId)).called(1);
      });

      test('getUserName returns a user name', () async {
        final userId = 'testUserId';
        final mockName = 'Test User';

        when(mockChatListRepository.getUserName(userId))
            .thenAnswer((_) async => mockName);

        final result = await chatListService.getUserName(userId);

        expect(result, mockName);
        verify(mockChatListRepository.getUserName(userId)).called(1);
      });

      test('getUnreadMessagesCount returns the count of unread messages',
          () async {
        final chatId = 'testChatId';
        final currentUserId = 'testUserId';
        final mockCount = 5;

        when(mockChatListRepository.getUnreadMessagesCount(
                chatId, currentUserId))
            .thenAnswer((_) async => mockCount);

        final result =
            await chatListService.getUnreadMessagesCount(chatId, currentUserId);

        expect(result, mockCount);
        verify(mockChatListRepository.getUnreadMessagesCount(
                chatId, currentUserId))
            .called(1);
      });
    });
  }



