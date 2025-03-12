import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/repositories/food_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

// FoodService class handles all the operations related to food items,
// including fetching, deleting, and saving food items, as well as fetching
// filter options and categories.

class FoodService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FoodRepository _foodRepository;

  // Constructor for FoodService, allows for an optional FoodRepository to be passed in.
  FoodService({FoodRepository? foodRepository})
      : _foodRepository = foodRepository ?? FoodRepository(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        );

  // Fetches filter options from the repository.
  Future<List<String>> fetchFilterOptions() async {
    return await _foodRepository.fetchFilterOptions();
  }

  // Deletes a food item by its document ID.
  Future<void> deleteFoodItem(String documentId) async {
    await _foodRepository.deleteFoodItem(documentId);
  }

  // Fetches the ingredients of the currently logged-in user.
  Future<List<String>> fetchUserIngredients() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user is logged in. Please log in first.');
    }
    return await _foodRepository.fetchUserIngredients(currentUser.uid);
  }

  // Saves a new food item with the provided details.
  Future<void> saveFoodItem({
    required String productName,
    required DateTime expiryDate,
    required int quantity,
    required String storageLocation,
    required String notes,
    required String category,
    required String? productImage,
  }) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('No user is logged in. Please log in first.');
    }

    await _foodRepository.addFoodItem({
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

  // Returns a stream of food items for the currently logged-in user.
  Stream<List<DocumentSnapshot>> getUserFoodItems() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user is logged in. Please log in first.');
    }
    return _foodRepository.getUserFoodItems(currentUser.uid);
  }

  // Fetches a food item by its ID.
  Future<Map<String, dynamic>?> fetchFoodItemById(String id) async {
    try {
      DocumentSnapshot doc = await _foodRepository.getFoodItemById(id);
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error fetching food item by id: $e');
    }
    return null;
  }

  // Fetches food categories from the repository.
  Future<List<String>> fetchFoodCategories() async {
    try {
      final snapshot = await _foodRepository.getCategories();
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