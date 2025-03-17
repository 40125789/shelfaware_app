import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/services/food_service.dart';


// FoodService instance
final foodServiceProvider = Provider<FoodService>((ref) {
  return FoodService();
});

// Stream provider for food items
final foodItemsProvider = StreamProvider.autoDispose<List<DocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser!;
  final foodService = ref.watch(foodServiceProvider);
  return foodService.getUserFoodItems();
});

// Stream provider for food items

class FoodItemNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  FoodItemNotifier() : super([]);

  // Existing methods...

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
}
// Future provider for categories (filters)
final filterOptionsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final foodService = ref.watch(foodServiceProvider);
  return foodService.fetchFoodCategories();
});
