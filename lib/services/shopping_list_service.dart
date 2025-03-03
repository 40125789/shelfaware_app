import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ShoppingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add product to shopping list
  Future<void> addToShoppingList(String productName) async {
    User? user = _auth.currentUser; // Get the current authenticated user
    if (user != null) {
      try {
        // Generate a unique ID for the product (using the document reference)
        String productId = _firestore.collection('shoppingList').doc().id;

        // Add document to Firestore in the shoppingList collection
        await _firestore.collection('shoppingList').doc(productId).set({
          'id': productId, // Store the unique product ID
          'productName': productName,
          'isPurchased': false,
          'user_id': user.uid, // Store the current user's UID
          'createdAt': FieldValue.serverTimestamp(),
          'quantity': 1, // Set initial quantity to 1
        });
        print('Product "$productName" added to shopping list');
      } catch (e) {
        print('Error adding product: $e');
      }
    }
  }

  // Toggle all items as purchased or not purchased for the current user
  Future<void> toggleAllPurchased(bool value) async {
    User? user = _auth.currentUser; // Get the current authenticated user
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('shoppingList')
            .where('user_id', isEqualTo: user.uid) // Filter by user_id
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.update({'isPurchased': value});
        }

        print('All items marked as ${value ? 'purchased' : 'not purchased'}');
      } catch (e) {
        print('Error toggling all items: $e');
      }
    }
  }

  // Update the quantity of the product by its ID
  Future<void> updateQuantity(String productId, int change) async {
    try {
      final snapshot = await _firestore
          .collection('shoppingList')
          .where('id', isEqualTo: productId) // Use the product ID
          .get();

      for (var doc in snapshot.docs) {
        final currentQuantity = doc.data()['quantity'] ?? 0;
        final newQuantity = currentQuantity + change;

        if (newQuantity > 0) {
          // Ensure the quantity does not go below 1
          await doc.reference.update({'quantity': newQuantity});
        }
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  // Get all products from shopping list for the current user
  Future<List<Map<String, dynamic>>> getShoppingList() async {
    User? user = _auth.currentUser; // Get the current authenticated user
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('shoppingList')
            .where('user_id', isEqualTo: user.uid) // Filter by user_id
            .get();
        return snapshot.docs.map((doc) => doc.data()).toList();
      } catch (e) {
        print('Error fetching shopping list: $e');
        return [];
      }
    }
    return [];
  }

  // Remove product from shopping list by product ID
Future<void> removeFromShoppingList(String itemId) async {
  User? user = _auth.currentUser; // Get the current authenticated user
  if (user != null) {
    try {
      // Use Firestore's document ID to identify the item
      final snapshot = await _firestore
          .collection('shoppingList')
          .where('user_id', isEqualTo: user.uid) // Filter by user_id
          .where('id', isEqualTo: itemId) // Filter by the item-specific 'id' field
          .get();

      for (var doc in snapshot.docs) {
        // Delete the document with the specific document ID (doc.id)
        await _firestore.collection('shoppingList').doc(doc.id).delete();
      }

      print('Item with id $itemId removed from shopping list');
    } catch (e) {
      print('Error removing item: $e');
    }
  }
}



//Mark item as purchased (update 'isPurchased' field)
// Modify this method in your ShoppingListService to handle individual item updates
Future<void> markAsPurchased(String itemId, bool newStatus) async {
  await FirebaseFirestore.instance
      .collection('shoppingList')
      .doc(itemId)
      .update({'isPurchased': newStatus});
}

    }
  




