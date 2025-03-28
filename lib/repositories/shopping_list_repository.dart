import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingListRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ShoppingListRepository(
      {required FirebaseFirestore firebaseFirestore,
      required FirebaseAuth firebaseAuth})
      : _firestore = firebaseFirestore,
        _auth = firebaseAuth;

  Future<void> addToShoppingList(String productName) async {
    User? user = _auth.currentUser;
    if (user != null) {
      String productId = _firestore.collection('shoppingList').doc().id;
      await _firestore.collection('shoppingList').doc(productId).set({
        'id': productId,
        'productName': productName,
        'isPurchased': false,
        'user_id': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'quantity': 1,
      });
    }
  }

  Future<void> toggleAllPurchased(bool value) async {
    User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('shoppingList')
          .where('user_id', isEqualTo: user.uid)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isPurchased': value});
      }
    }
  }

  Future<void> updateQuantity(String productId, int change) async {
    User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('shoppingList')
          .where('user_id', isEqualTo: user.uid)
          .where('id', isEqualTo: productId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final currentQuantity = (doc.data()['quantity'] as int?) ?? 0;
        final newQuantity = currentQuantity + change;

        if (newQuantity > 0) {
          await doc.reference.update({'quantity': newQuantity});
        } else {
          await doc.reference
              .delete(); // Remove the item if quantity becomes zero or less
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getShoppingList() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('shoppingList')
          .where('user_id', isEqualTo: user.uid)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include the document ID in the returned data
        return data;
      }).toList();
    }
    return [];
  }

  Future<void> removeFromShoppingList(String itemId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('shoppingList')
          .where('user_id', isEqualTo: user.uid)
          .where('id', isEqualTo: itemId)
          .get();

      for (var doc in snapshot.docs) {
        await _firestore.collection('shoppingList').doc(doc.id).delete();
      }
    }
  }

  Future<void> markAsPurchased(String itemId, bool newStatus) async {
    await _firestore
        .collection('shoppingList')
        .doc(itemId)
        .update({'isPurchased': newStatus});
  }
}
