import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';


class FoodItemNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  FoodItemNotifier() : super([]);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchFoodItems(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('foodItems')
          .where('userId', isEqualTo: userId)
          .get();

      final foodItems = snapshot.docs.map((doc) {
        final data = doc.data();
        data['documentId'] = doc.id;
        return data;
      }).toList();

      state = foodItems;
    } catch (e) {
      print('Error fetching food items: $e');
    }
  }

  Future<void> updateFoodItem(String documentId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('foodItems').doc(documentId).update(updatedData);
      fetchFoodItems(updatedData['userId']);
    } catch (e) {
      print('Error updating food item: $e');
    }
  }

  Future<void> deleteFoodItem(String documentId, String userId) async {
    try {
      await _firestore.collection('foodItems').doc(documentId).delete();
      fetchFoodItems(userId);
    } catch (e) {
      print('Error deleting food item: $e');
    }
  }

  Future<void> donateFoodItem(String documentId, String userId, Position userPosition) async {
    try {
      // Implement the donation logic here
      fetchFoodItems(userId);
    } catch (e) {
      print('Error donating food item: $e');
    }
  }
}




  Future<Map<String, dynamic>?> fetchFoodItemById(String documentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('foodItems')
          .doc(documentId)
          .get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('Error fetching food item by ID: $e');
    }
    return null;
  }


final foodItemProvider = StateNotifierProvider<FoodItemNotifier, List<Map<String, dynamic>>>(
  (ref) => FoodItemNotifier(),
);