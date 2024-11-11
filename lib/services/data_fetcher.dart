import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/food_item.dart';

class DataFetcher {
  static Future<List<FoodItem>> fetchFoodItems() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('foodItems')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    return snapshot.docs.map((doc) {
      return FoodItem.fromDocument(doc);
    }).toList();
  }
}
