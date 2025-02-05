import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class FoodSuggestionsService {
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
          .map((doc) => doc['productName'] as String?)
          .where((productName) => productName != null)
          .cast<String>()
          .toList();

      suggestions.addAll(foodItemSuggestions);

      // Fetch from the 'history' collection (user's past entries)
      QuerySnapshot historySnapshot = await FirebaseFirestore.instance
          .collection('history')
          .where('productName', isGreaterThanOrEqualTo: query)
          .where('productName', isLessThan: query + 'z')
          .get();

      List<String> historySuggestions = historySnapshot.docs
          .map((doc) => doc['productName'] as String?)
          .where((productName) => productName != null)
          .cast<String>()
          .toList();

      suggestions.addAll(historySuggestions);

      // If not enough suggestions, fetch from OpenFoodFacts
      if (suggestions.isEmpty) {
        List<String> openFoodFactsSuggestions =
            await fetchFromOpenFoodFacts(query);
        suggestions.addAll(openFoodFactsSuggestions);
      }

      // Remove duplicates by converting to a Set and then back to a List
      suggestions = suggestions.toSet().toList();

      return suggestions;
    } catch (e) {
      print('Error fetching food suggestions: $e');
      return [];
    }
  }

  Future<List<String>> fetchFromOpenFoodFacts(String query) async {
    final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['products'] != null) {
          return (data['products'] as List)
              .where((product) => product['product_name'] != null)
              .map<String>((product) => product['product_name'] as String)
              .toList();
        }
      } else if (response.statusCode == 429) {
        print('Rate limit exceeded. Retrying in 1 second...');
        await Future.delayed(Duration(seconds: 1));
        return fetchFromOpenFoodFacts(query); // Retry once
      } else {
        print(
            'Failed to fetch data from OpenFoodFacts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data from OpenFoodFacts: $e');
    }

    return [];
  }
}
