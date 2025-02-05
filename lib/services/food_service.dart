import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/repositories/food_repository.dart';

class FoodService implements FoodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<String>> fetchFilterOptions() async {
    QuerySnapshot snapshot = await _firestore.collection('categories').get();
    List<String> categories = snapshot.docs.map((doc) {
      final foodType = doc['Food Type'];
      return foodType?.toString() ?? '';
    }).toList();

    categories.removeWhere((category) => category.isEmpty);
    return categories;
  }

  @override
  Future<void> deleteFoodItem(String documentId) async {
    await _firestore.collection('foodItems').doc(documentId).delete();
  }

  @override
  Future<List<String>> fetchUserIngredients(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('foodItems')
          .where('userId', isEqualTo: userId)
          .get();

      List<String> ingredients = snapshot.docs
          .map((doc) => doc['productName'] as String) // Assuming the field is 'productName'
          .toList();

      return ingredients;
    } catch (e) {
      print('Error fetching ingredients: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFoodHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('history')
          .where('userId', isEqualTo: userId)
          .orderBy('addedOn', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'productName': doc['productName'] ?? '',
          'category': doc['category'] ?? '',
          'status': doc['status'] ?? '',
          'expiryDate': doc['expiryDate'] ?? '',
          'updatedOn': doc['updatedOn'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching food history: $e');
      return [];
    }
  }
}