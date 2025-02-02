import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shelfaware_app/services/firebase_service.dart'; // Assuming your FirebaseService is in this file


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Ensure dotenv is properly configured
import 'firebase_service.dart'; // Make sure you have this service correctly implemented

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Ensure dotenv is properly configured
import 'firebase_service.dart'; // Make sure you have this service correctly implemented

class WasteAnalyticsService {
  // This method now accepts foodHistory directly
  Future<String> getWasteAnalytics(List<Map<String, dynamic>> foodHistory) async {
    if (foodHistory.isEmpty) {
      return "No food history found.";
    }

    // Aggregate the data as before
    Map<String, Map<String, int>> aggregatedData = {};
    int totalConsumed = 0;
    int totalDiscarded = 0;
    Map<String, int> reasonsForWaste = {}; // Map to store reasons for waste

    for (var food in foodHistory) {
      String category = food['category'] ?? '';
      String status = food['status'] ?? '';
      int quantity = food['quantity'] ?? 0;  // Ensure quantity is never null
      String reason = food['reason'] ?? '';  // Fetch reason from the 'reason' field

      // Initialize the category in the map if not already present
      if (!aggregatedData.containsKey(category)) {
        aggregatedData[category] = {'discarded': 0, 'consumed': 0};
      }

      // Aggregate the data based on status
      if (status == 'discarded') {
        aggregatedData[category]!['discarded'] = aggregatedData[category]!['discarded']! + quantity;
        totalDiscarded += quantity;

        // Track reasons for waste (from the 'reason' field)
        if (reason.isNotEmpty) {
          if (!reasonsForWaste.containsKey(reason)) {
            reasonsForWaste[reason] = 0;
          }
          reasonsForWaste[reason] = reasonsForWaste[reason]! + quantity;
        }
      } else if (status == 'consumed') {
        aggregatedData[category]!['consumed'] = aggregatedData[category]!['consumed']! + quantity;
        totalConsumed += quantity;
      }
    }

    // Step 3: Generate insights
    int totalCategories = aggregatedData.length;
    double totalFood = totalConsumed.toDouble() + totalDiscarded.toDouble();
    double discardPercentage = totalFood > 0 ? (totalDiscarded / totalFood) * 100 : 0;
    double consumedPercentage = totalFood > 0 ? (totalConsumed / totalFood) * 100 : 0;

    // Find the category with the highest waste
    String highestWasteCategory = '';
    int highestWasteAmount = 0;
    aggregatedData.forEach((category, values) {
      if (values['discarded']! > highestWasteAmount) {
        highestWasteAmount = values['discarded']!;
        highestWasteCategory = category;
      }
    });

    // Format the insights message for display
    String insights = "Here are some insights about your food waste habits:\n\n";
    insights += "- Total Categories: $totalCategories\n";
    insights += "- Total food discarded: $totalDiscarded items\n";
    insights += "- Total food consumed: $totalConsumed items\n";
    insights += "- Percentage of food discarded: ${discardPercentage.toStringAsFixed(2)}%\n";
    insights += "- Percentage of food consumed: ${consumedPercentage.toStringAsFixed(2)}%\n";

    if (highestWasteCategory.isNotEmpty) {
      insights += "- The category with the highest waste is '$highestWasteCategory' with $highestWasteAmount items discarded.\n";
    }

    // Insights into reasons for waste (from the 'reason' field)
    if (reasonsForWaste.isNotEmpty) {
      insights += "\nReasons for discarded items:\n";
      reasonsForWaste.forEach((reason, quantity) {
        insights += "  - $reason: $quantity items discarded\n";
      });
    }

    insights += "\nSuggestions for improvement:\n";
    if (discardPercentage > 50) {
      insights += "- Consider reducing your purchase of items from categories with high discard rates.\n";
    }
    if (consumedPercentage < 50) {
      insights += "- Try to consume more from categories with lower consumption rates.\n";
    }

    return insights;
  }
}
