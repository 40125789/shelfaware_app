import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, int>> fetchExpiringItems(String userId) async {
  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('foodItems')
        .where('userId', isEqualTo: userId)
        .get();

    int expiringSoonCount = 0;
    int expiredCount = 0;
    DateTime today = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp expiryTimestamp = data['expiryDate'];
      DateTime expiryDate = expiryTimestamp.toDate();

      if (expiryDate.isBefore(today) && expiryDate.difference(today).inDays <= 0) {
        expiredCount++;
      } else if (expiryDate.isAfter(today) && expiryDate.difference(today).inDays <= 3) {
        expiringSoonCount++;
      }
    }

    return {'expiringSoonCount': expiringSoonCount, 'expiredCount': expiredCount};
  } catch (e) {
    print('Error fetching expiring items: $e');
    return {'expiringSoonCount': 0, 'expiredCount': 0};
  }
}

Future<List<String>> fetchFoodCategories() async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
    return snapshot.docs
        .map((doc) => doc['Food Type']?.toString() ?? '')
        .where((category) => category.isNotEmpty)
        .toList();
  } catch (e) {
    print('Error fetching food categories: $e');
    return [];
  }
}

