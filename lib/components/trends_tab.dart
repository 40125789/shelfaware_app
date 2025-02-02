import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:shelfaware_app/components/line_chart.dart' as custom;
import 'package:shelfaware_app/components/line_chart.dart';
import 'package:shelfaware_app/components/card_tiles.dart';
// Assuming you're using the pie_chart package

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';  // Make sure you have the fl_chart package

import 'package:flutter/material.dart';
import 'package:shelfaware_app/services/firebase_service.dart';
import 'package:shelfaware_app/services/openai_service.dart'; // Ensure this import is correct and the file exists

class WasteAnalyticsTab extends StatefulWidget {
  final String userId; // Add userId as a parameter

  WasteAnalyticsTab({required this.userId});

  @override
  _WasteAnalyticsTabState createState() => _WasteAnalyticsTabState();
}

class _WasteAnalyticsTabState extends State<WasteAnalyticsTab> {
  late Future<String> wasteAnalyticsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the waste analytics future by fetching the insights
    wasteAnalyticsFuture = _fetchWasteAnalytics(widget.userId); // Pass userId here
  }

  Future<String> _fetchWasteAnalytics(String userId) async {
    FirebaseService firebaseService = FirebaseService();

    // Fetch food history from Firebase, passing the userId
    List<Map<String, dynamic>> foodHistory;
    try {
      foodHistory = await firebaseService.getFoodHistory(userId);  // Use userId to fetch data
    } catch (e) {
      return "Error fetching food history: $e";
    }

    if (foodHistory.isEmpty) {
      return "No food history found.";
    }

    // Pass food history to WasteAnalyticsService
    WasteAnalyticsService wasteService = WasteAnalyticsService();
    String insights = await wasteService.getWasteAnalytics(foodHistory);

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Analytics'),
      ),
      body: FutureBuilder<String>(
        future: wasteAnalyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No insights available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(snapshot.data!, style: TextStyle(fontSize: 16)),
          );
        },
      ),
    );
  }
}
