import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/repositories/chat_list_repository.dart';
import 'package:shelfaware_app/services/chat_list_service.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';

final chatListRepositoryProvider = Provider<ChatListRepository>((ref) {
  return ChatListRepository(
    firebaseFirestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  );
});

final chatListServiceProvider = Provider<ChatListService>((ref) {
  final chatListRepository = ref.watch(chatListRepositoryProvider);
  return ChatListService(chatListRepository);
});

final chatStreamProvider = StreamProvider.family<QuerySnapshot, bool>((ref, isDescending) {
  final chatListService = ref.watch(chatListServiceProvider);
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return chatListService.getChats(user.uid, isDescending);
      } else {
        return Stream.empty(); // Return an empty stream if the user is not authenticated
      }
    },
    loading: () => Stream.empty(), // Return an empty stream while loading
    error: (_, __) => Stream.empty(), // Return an empty stream on error
  );
});