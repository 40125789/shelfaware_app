// notification_handler.dart

import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/food_item.dart'; // Corrected import path
import 'package:shelfaware_app/services/expiry_notifier.dart';
import 'package:shelfaware_app/services/data_fetcher.dart';

class NotificationHandler {
  final ExpiryNotifier _expiryNotifier;
  final BuildContext context;

  NotificationHandler({required this.context, required ExpiryNotifier expiryNotifier})
      : _expiryNotifier = expiryNotifier;

  Future<void> _handleNotificationPress() async {
    // Fetch the list of expiring items
    List<FoodItem> foodItems = await _fetchFoodItems();

    // Get expiring items
    List<String> expiringItems = await _expiryNotifier.getExpiringItems(foodItems);

    // If no expiring items, show a message
    if (expiringItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expiring items right now!')),
      );
      return;
    }

    // Show dialog with the expiring items
    _showExpiryDialog(expiringItems);
  }

  Future<List<FoodItem>> _fetchFoodItems() async {
    return await DataFetcher.fetchFoodItems();  // Call to data fetcher class
  }

  void _showExpiryDialog(List<String> expiringItems) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Expiring Items'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: expiringItems.map((item) => Text(item)).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
