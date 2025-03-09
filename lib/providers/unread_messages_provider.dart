import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/services/unread_messages_service.dart';
import 'package:shelfaware_app/repositories/unread_messages_repository.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';

final unreadMessagesRepositoryProvider = Provider((ref) => UnreadMessagesRepository(
  firestore: FirebaseFirestore.instance, 
  auth: FirebaseAuth.instance
));
final unreadMessagesServiceProvider = Provider((ref) {
  final repository = ref.watch(unreadMessagesRepositoryProvider);
  return UnreadMessagesService(repository);
});

final unreadMessagesCountProvider = StreamProvider.autoDispose<int>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  
  if (user == null) {
    return Stream.value(0);
  }

  final service = ref.watch(unreadMessagesServiceProvider);
  return service.getUnreadMessagesCount(user.uid);
});