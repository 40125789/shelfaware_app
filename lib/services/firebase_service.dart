import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch current authenticated user
  User? get currentUser => _auth.currentUser;

  // Fetch ingredients for the authenticated user
  Future<List<String>> fetchUserIngredients() async {
    User? user = currentUser;

    if (user != null) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('foodItems')
            .where('userId', isEqualTo: user.uid)
            .get();

        List<String> ingredients = snapshot.docs
            .map((doc) => doc['productName'] as String) // Assuming the field is 'productName'
            .toList();

        return ingredients;
      } catch (e) {
        print('Error fetching ingredients: $e');
        return [];
      }
    } else {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHistoryData(String userId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: userId)
        .get();

    return querySnapshot.docs.map((doc) {
      return doc.exists ? Map<String, dynamic>.from(doc.data() as Map<String, dynamic>) : <String, dynamic>{};
    }).toList();
  }


  // Fetch food history for the authenticated user
  Future<List<Map<String, dynamic>>> getFoodHistory(String userId) async {
    User? user = currentUser;
    String userId = user?.uid ?? '';
    
    if (userId.isEmpty) return [];

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
