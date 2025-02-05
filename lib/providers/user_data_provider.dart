import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/models/user_model.dart';


final userDataProvider = FutureProvider<UserData>((ref) async {
  final user = FirebaseAuth.instance.currentUser!;
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final data = userDoc.data()!;
  return UserData(firstName: data['firstName'], lastName: data['lastName']);
});

final filterOptionsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    List<String> categories = snapshot.docs.map((doc) {
      final foodType = doc['Food Type'];
      return foodType?.toString() ?? '';
    }).toList();
    categories.removeWhere((category) => category.isEmpty);
    return ['All', ...categories];
  } catch (e) {
    throw Exception('Error fetching filter options: $e');
  }
});
