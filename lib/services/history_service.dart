import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/food_history.dart';


class HistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<FoodHistory>> getFoodHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('history')
          .where('userId', isEqualTo: userId)
          .orderBy('addedOn', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return FoodHistory.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching food history: $e');
      return [];
    }
  }
}
