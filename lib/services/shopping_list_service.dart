import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/repositories/shopping_list_repository.dart';

class ShoppingListService {
  final ShoppingListRepository _shoppingListRepository;

  ShoppingListService({ShoppingListRepository? shoppingListRepository})
      : _shoppingListRepository = shoppingListRepository ?? ShoppingListRepository(
          firebaseFirestore: FirebaseFirestore.instance,
          firebaseAuth: FirebaseAuth.instance,
        );

  Future<void> addToShoppingList(String productName) async {
    await _shoppingListRepository.addToShoppingList(productName);
  }

  Future<void> toggleAllPurchased(bool value) async {
    await _shoppingListRepository.toggleAllPurchased(value);
  }

  Future<void> updateQuantity(String productId, int change) async {
    await _shoppingListRepository.updateQuantity(productId, change);
  }

  Future<List<Map<String, dynamic>>> getShoppingList() async {
    return await _shoppingListRepository.getShoppingList();
  }

  Future<void> removeFromShoppingList(String itemId) async {
    await _shoppingListRepository.removeFromShoppingList(itemId);
  }

  Future<void> markAsPurchased(String itemId, bool newStatus) async {
    await _shoppingListRepository.markAsPurchased(itemId, newStatus);
  }
}


