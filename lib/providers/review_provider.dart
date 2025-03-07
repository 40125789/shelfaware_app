import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final reviewProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, loggedInUserId) {
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('donorId', isEqualTo: loggedInUserId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  });
});
