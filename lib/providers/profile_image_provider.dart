import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileImageProvider = FutureProvider.family<String?, String>((ref, uid) async {
  try {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      return userDoc.data()!['profileImageUrl'];  
    }
    return null;
  } catch (e) {
    debugPrint('Error loading profile image: $e');
    return null;
  }
});

final profileImageStateProvider = StateProvider<String?>((ref) => null);

final userProvider = StateProvider<User?>((ref) => FirebaseAuth.instance.currentUser);
