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

class GoalSettingTab extends StatelessWidget {
  final String userId; // Add userId as a parameter

  // Constructor to accept userId
  const GoalSettingTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: SingleChildScrollView( // Wrap the content in a SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal 1 - Food Saved (Including Donations)
            GoalCard(
              userId: userId,
              title: "Save 20 Items (Including Donations)",
              progress: 0.6, // 60% progress
              currentStatus: "You’ve saved 12 items, including 5 donations, out of 20 items this month.",
              onEdit: () {
                // Edit goal action
              },
              onReset: () {
                // Reset goal action
              },
            ),
            
            SizedBox(height: 16),

            // Goal 2 - Food Waste Reduction
            GoalCard(
              userId: userId,
              title: "Reduce Food Waste by 25%",
              progress: 0.5, // 50% progress
              currentStatus: "You’ve reduced waste by 15% this month (5 items out of 30).",
              onEdit: () {
                // Edit goal action
              },
              onReset: () {
                // Reset goal action
              },
            ),
            
            SizedBox(height: 16),

            // Goal 3 - Food Donations
            GoalCard(
              userId: userId,
              title: "Donate 10 Food Items",
              progress: 0.7, // 70% progress
              currentStatus: "You’ve donated 7 out of 10 items this month.",
              onEdit: () {
                // Edit goal action
              },
              onReset: () {
                // Reset goal action
              },
            ),

            SizedBox(height: 32),

            // Create New Goal Button
            ElevatedButton(
              onPressed: () {
                // Navigate to the Create New Goal page
              },
              child: Text('Create New Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final String userId; // Add userId here as well
  final String title;
  final double progress; // Progress as a fraction (0.0 - 1.0)
  final String currentStatus;
  final VoidCallback onEdit;
  final VoidCallback onReset;

  const GoalCard({
    required this.userId,
    required this.title,
    required this.progress,
    required this.currentStatus,
    required this.onEdit,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Progress bar for each goal
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
            SizedBox(height: 8),
            Text(
              currentStatus,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: onEdit,
                  child: Text("Edit Goal"),
                ),
                ElevatedButton(
                  onPressed: onReset,
                  child: Text("Reset Goal"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


