import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/repositories/food_item_repository.dart';

class FoodItemService {
  final FoodItemRepository _repository;

  FoodItemService({FoodItemRepository? repository})
      : _repository = repository ?? FoodItemRepository();

  Future<void> saveFoodItem({
    required String productName,
    required DateTime expiryDate,
    required int quantity,
    required String storageLocation,
    required String notes,
    required String category,
    required String? productImage,
  }) async {
    User? currentUser = _repository.getCurrentUser();

    if (currentUser == null) {
      throw Exception('No user is logged in. Please log in first.');
    }

    await _repository.addFoodItem({
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

  Stream<List<DocumentSnapshot>> getUserFoodItems(String userId) {
    return _repository.getUserFoodItems(userId);
  }

  Future<Map<String, dynamic>?> fetchFoodItemById(String id) async {
    try {
      DocumentSnapshot doc = await _repository.getFoodItemById(id);
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error fetching food item by id: $e');
    }
    return null;
  }

  Future<List<String>> fetchFoodCategories() async {
    try {
      final snapshot = await _repository.getCategories();
      List<String> categories = snapshot
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