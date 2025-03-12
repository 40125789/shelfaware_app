import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FoodRepository({required this.firestore, required this.auth});



  Future<List<String>> fetchFilterOptions() async {
    QuerySnapshot snapshot = await firestore.collection('categories').get();
    List<String> categories = snapshot.docs.map((doc) {
      final foodType = doc['Food Type'];
      return foodType?.toString() ?? '';
    }).toList();

    categories.removeWhere((category) => category.isEmpty);
    return categories;
  }

  Future<void> deleteFoodItem(String documentId) async {
    await firestore.collection('foodItems').doc(documentId).delete();
  }

  Future<List<String>> fetchUserIngredients(String userId) async {
    try {
      QuerySnapshot snapshot = await firestore
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


  Future<void> addFoodItem(Map<String, dynamic> foodItemData) async {
    await firestore.collection('foodItems').add(foodItemData);
  }

  Stream<List<DocumentSnapshot>> getUserFoodItems(String userId) {
    return firestore
        .collection('foodItems')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<DocumentSnapshot> getFoodItemById(String id) async {
    return await firestore.collection('foodItems').doc(id).get();
  }

  Future<List<DocumentSnapshot>> getCategories() async {
    QuerySnapshot snapshot = await firestore.collection('categories').get();
    return snapshot.docs;
  }
}