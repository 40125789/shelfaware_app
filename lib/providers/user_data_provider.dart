import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/models/user_model.dart';
import 'package:shelfaware_app/repositories/user_repository.dart';
import 'package:shelfaware_app/services/user_service.dart';


final userProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = FirebaseAuth.instance.currentUser!;
  final userRepository = UserRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
  final userService = UserService(userRepository);
  return await userService.getUserData(user.uid);
});



