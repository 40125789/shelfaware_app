import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/food_history.dart';

class HistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Function to fetch food items from the 'history' collection
  Future<List<FoodHistory>> getHistoryItems(String userId) async {
    QuerySnapshot snapshot = await _db
        .collection('history') // Fetch from the 'history' collection
        .where('userId', isEqualTo: userId) // Filter by userId
        .orderBy('addedOn', descending: true) // Optional: Order by date added
        .get();

    // Convert snapshot documents into a list of FoodItem objects
    List<FoodHistory> foodItems = snapshot.docs.map((doc) {
      return FoodHistory.fromFirestore(doc.data() as Map<String, dynamic>);
    }).toList();

    return foodItems;
  }
}
