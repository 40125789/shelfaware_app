import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodItemRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FoodItemRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> addFoodItem(Map<String, dynamic> foodItemData) async {
    await _firestore.collection('foodItems').add(foodItemData);
  }

  Stream<List<DocumentSnapshot>> getUserFoodItems(String userId) {
    return _firestore
        .collection('foodItems')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<DocumentSnapshot> getFoodItemById(String id) async {
    return await _firestore.collection('foodItems').doc(id).get();
  }

  Future<List<DocumentSnapshot>> getCategories() async {
    return await _firestore.collection('categories').get().then((snapshot) => snapshot.docs);
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}