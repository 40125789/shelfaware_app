import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Service to interact with food-related data
class FoodItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveFoodItem({
    required String productName,
    required DateTime expiryDate,
    required int quantity,
    required String storageLocation,
    required String notes,
    required String category,
    required String? productImage,
  }) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('No user is logged in. Please log in first.');
    }

    await _firestore.collection('foodItems').add({
      'productName': productName,
      'expiryDate': expiryDate,
      'quantity': quantity,
      'userId': currentUser.uid,
      'storageLocation': storageLocation,
      'notes': notes,
      'category': category,
      'addedOn': DateTime.now(),
      'productImage': productImage,
    });
  }



  // Fetch food items for a specific user
  Stream<List<DocumentSnapshot>> getUserFoodItems(String userId) {
    return _firestore
        .collection('foodItems')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Fetch food item by ID

    Future<Map<String, dynamic>?> fetchFoodItemById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('foodItems').doc(id).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error fetching food item by id: $e');
    }
    return null;
  }

  // Fetch categories for filter options
  Future<List<String>> fetchFoodCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      List<String> categories = snapshot.docs
          .map((doc) => doc['Food Type']?.toString() ?? '')
          .toList();
      categories.removeWhere((category) => category.isEmpty);
      return ['All', ...categories];
    } catch (e) {
      print('Error fetching filter options: $e');
      return ['All'];
    }
  }
}
