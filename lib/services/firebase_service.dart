import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<List<String>> fetchUserIngredients() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('foodItems')
        .where('userId', isEqualTo: user.uid)
        .get();

    List<String> ingredients = snapshot.docs
        .map((doc) => doc['productName'] as String) // Assuming the field is 'productName'
        .toList();

    return ingredients;
  } else {
    return [];
  }
}
