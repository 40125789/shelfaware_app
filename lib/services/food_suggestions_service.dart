import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<String>> fetchFoodSuggestions(String query) async {
  if (query.isEmpty) {
    return [];
  }

  try {
    List<String> suggestions = [];

    // Fetch from the 'foodItems' collection
    QuerySnapshot foodItemsSnapshot = await FirebaseFirestore.instance
        .collection('foodItems')
        .where('productName', isGreaterThanOrEqualTo: query)
        .where('productName', isLessThan: query + 'z')
        .get();

    List<String> foodItemSuggestions = foodItemsSnapshot.docs
        .map((doc) => doc['productName'] as String)
        .toList();

    suggestions.addAll(foodItemSuggestions);

    // Fetch from the 'history' collection (user's past entries)
    QuerySnapshot historySnapshot = await FirebaseFirestore.instance
        .collection('history')
        .where('productName', isGreaterThanOrEqualTo: query)
        .where('productName', isLessThan: query + 'z')
        .get();

    List<String> historySuggestions = historySnapshot.docs
        .map((doc) => doc['productName'] as String)
        .toList();

    suggestions.addAll(historySuggestions);

    return suggestions;
  } catch (e) {
    print('Error fetching food suggestions: $e');
    return [];
  }
}