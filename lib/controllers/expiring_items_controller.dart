
import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/food_item.dart';
import 'package:shelfaware_app/services/data_fetcher.dart'; 
import 'package:shelfaware_app/components/expired_items_tab.dart';
import 'package:shelfaware_app/components/expiring_items_tab.dart';

// Controller class to manage the state of the Expiring Items screen
class ExpiringItemsController extends ChangeNotifier {
  List<FoodItem> expiringItems = []; // List to store food items
  bool _isLoading = false; // Loading state flag
  bool get isLoading => _isLoading;

  // Fetch food items from Firestore using the DataFetcher
  Future<void> fetchFoodItems() async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that loading has started

    try {
      List<FoodItem> fetchedItems = await DataFetcher.fetchFoodItems();
      expiringItems = fetchedItems; // Update the list
    } catch (e) {
      print('Error fetching food items: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that loading has finished
    }
  }

  // Expiring Soon Items (expiring within 3 days)
  List<FoodItem> get expiringSoonItems {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(Duration(days: 3));
    return expiringItems.where((item) {
      final expiryDate = item.expiryDate;
      return expiryDate.isAfter(now) && expiryDate.isBefore(threeDaysFromNow);
    }).toList();
  }

  // Expired Items
  List<FoodItem> get expiredItems {
    final now = DateTime.now();
    return expiringItems.where((item) {
      final expiryDate = item.expiryDate;
      return expiryDate.isBefore(now);
    }).toList();
  }
}

