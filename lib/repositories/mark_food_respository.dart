import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/models/mark_food.dart';


class MarkFoodRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MarkFoodRepository({required FirebaseFirestore firebaseFirestore, required FirebaseAuth auth})
      : _firestore = firebaseFirestore,
        _auth = auth;

  Future<MarkFood?> fetchFoodItem(String documentId) async {
    final foodItemRef = _firestore.collection('foodItems').doc(documentId);
    final foodItemSnapshot = await foodItemRef.get();
    if (foodItemSnapshot.exists) {
      return MarkFood.fromMap(foodItemSnapshot.data()!, foodItemSnapshot.id);
    }
    return null;
  }

  Future<void> updateFoodItem(MarkFood foodItem) async {
    final foodItemRef = _firestore.collection('foodItems').doc(foodItem.id);
    await foodItemRef.update(foodItem.toMap());
  }

  Future<void> deleteFoodItem(String documentId) async {
    final foodItemRef = _firestore.collection('foodItems').doc(documentId);
    await foodItemRef.delete();
  }

  Future<void> addHistory(Map<String, dynamic> historyData) async {
    await _firestore.collection('history').add(historyData);
  }
}