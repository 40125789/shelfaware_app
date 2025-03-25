import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class FoodSuggestionsRepository {
  final FirebaseFirestore _firestore;
  final http.Client _httpClient;

  FoodSuggestionsRepository(
      {FirebaseFirestore? firestore, http.Client? httpClient})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _httpClient = httpClient ?? http.Client();

  Future<List<String>> fetchFoodItems(String query) async {
    QuerySnapshot foodItemsSnapshot = await _firestore
        .collection('foodItems')
        .where('productName', isGreaterThanOrEqualTo: query)
        .where('productName', isLessThan: query + 'z')
        .get();

    return foodItemsSnapshot.docs
        .map((doc) => doc['productName'] as String?)
        .where((productName) => productName != null)
        .cast<String>()
        .toList();
  }

  Future<List<String>> fetchHistoryItems(String query) async {
    QuerySnapshot historySnapshot = await _firestore
        .collection('history')
        .where('productName', isGreaterThanOrEqualTo: query)
        .where('productName', isLessThan: query + 'z')
        .get();

    return historySnapshot.docs
        .map((doc) => doc['productName'] as String?)
        .where((productName) => productName != null)
        .cast<String>()
        .toList();
  }
}
