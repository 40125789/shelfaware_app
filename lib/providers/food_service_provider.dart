import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/services/food_item_service.dart';


// FoodService instance
final foodServiceProvider = Provider<FoodItemService>((ref) {
  return FoodItemService();
});

// Stream provider for food items
final foodItemsProvider = StreamProvider.autoDispose<List<DocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser!;
  final foodService = ref.watch(foodServiceProvider);
  return foodService.getUserFoodItems(user.uid);
});

// Future provider for categories (filters)
final filterOptionsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final foodService = ref.watch(foodServiceProvider);
  return foodService.fetchFoodCategories();
});
