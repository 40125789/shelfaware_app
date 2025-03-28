import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FoodUtils {
  /// Group items by expiry status (Expired, Expiring Soon, Fresh)
  static Map<String, List<QueryDocumentSnapshot>> groupItemsByExpiry(
      List<QueryDocumentSnapshot> items) {
    final groupedItems = <String, List<QueryDocumentSnapshot>>{
      'Expired': [],
      'Expiring Soon': [],
      'Fresh': []
    };

    final now = DateTime.now();

    for (var item in items) {
      final data = item.data() as Map<String, dynamic>?;

      // Skip invalid or null data
      if (data == null || !data.containsKey('expiryDate')) {
        continue;
      }

      final expiryTimestamp = data['expiryDate'] as Timestamp;
      final expiryDate = expiryTimestamp.toDate();
      final difference = expiryDate.difference(now).inDays;

      if (difference < 0) {
        groupedItems['Expired']!.add(item);
      } else if (difference <= 4) {
        groupedItems['Expiring Soon']!.add(item);
      } else {
        groupedItems['Fresh']!.add(item);
      }
    }

    return groupedItems;
  }

  /// Get color for category based on expiry status
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Expired':
        return Colors.red;
      case 'Expiring Soon':
        return Colors.orange;
      case 'Fresh':
        return Colors.green;
      default:
        return Colors.blueAccent;
    }
  }

  /// Format expiry date into a human-readable string
  static String formatExpiryDate(Timestamp expiryTimestamp) {
    DateTime expiryDate = expiryTimestamp.toDate();
    DateTime today = DateTime.now();
    int daysDifference = expiryDate.difference(today).inDays;

    if (daysDifference < 0) {
      return 'Expired';
    } else if (daysDifference == 0) {
      return 'Expires today';
    } else {
      return 'Expires in: $daysDifference day${daysDifference == 1 ? '' : 's'}';
    }
  }
}
