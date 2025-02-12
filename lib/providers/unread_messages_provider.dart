import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/services/unread_messages_service.dart';


final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  return UnreadMessagesService().getUnreadMessagesCount(userId);
});
