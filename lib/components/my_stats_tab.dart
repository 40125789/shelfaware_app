import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:pie_chart/pie_chart.dart' as pie_chart;
import 'package:shelfaware_app/components/additional_stats_widget.dart'; // Assuming you're using the pie_chart package

class MyStatsTab extends StatefulWidget {
  final String userId;

  MyStatsTab({required this.userId});

  @override
  _MyStatsTabState createState() => _MyStatsTabState();
}

class _MyStatsTabState extends State<MyStatsTab>
    with SingleTickerProviderStateMixin {
  late Future<UserStats> _userStats;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _userStats = fetchUserStats(widget.userId);

    // Initialize AnimationController
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward(); // Start the animation
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<UserStats> fetchUserStats(String userId) async {
  var snapshot = await FirebaseFirestore.instance
      .collection('history')
      .where('userId', isEqualTo: userId)
      .get();

  int consumed = 0;
  int discarded = 0;
  Map<String, int> wastedFoodItems = {};
  Map<String, int> categoryCounts = {};
  List<int> shelfLifeDifferences = [];

  for (var doc in snapshot.docs) {
    String status = doc['status'] ?? '';
    String foodName = doc['productName'] ?? '';
    String category = doc['category'] ?? '';
    DateTime addedDate = (doc['addedOn'] as Timestamp).toDate();
    DateTime? updatedDate = doc['updatedOn'] != null
        ? (doc['updatedOn'] as Timestamp).toDate()
        : null;

    if (status == 'consumed') {
      consumed++;
    } else if (status == 'discarded' && updatedDate != null) {
      discarded++;
      // Track most wasted food items
      wastedFoodItems[foodName] = (wastedFoodItems[foodName] ?? 0) + 1;

      // Track most common category of wasted foods
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

      // Track shelf life based on the updatedOn date (discarded date)
      int shelfLife = updatedDate.difference(addedDate).inDays;
      shelfLifeDifferences.add(shelfLife);
    }
  }

  // Fetch completed donations
  var donationSnapshot = await FirebaseFirestore.instance
      .collection('donations')
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: 'completed') // Only completed donations
      .get();

  int donated = donationSnapshot.docs.length;

  // Calculate the average shelf life
  double avgShelfLife = 0;
  if (shelfLifeDifferences.isNotEmpty) {
    avgShelfLife = shelfLifeDifferences.reduce((a, b) => a + b) /
        shelfLifeDifferences.length;
  }

  // Find the most wasted food item (discarded more than once)
  String mostWastedFoodItem = 'Not enough data';
  if (wastedFoodItems.isNotEmpty) {
    // Only consider food items discarded more than once
    var mostWasted = wastedFoodItems.entries
        .where((entry) => entry.value > 1)  // Filter food items discarded more than once
        .fold<MapEntry<String, int>?>(
          null,
          (previous, current) {
            if (previous == null || current.value > previous.value) {
              return current;
            }
            return previous;
          },
        );

    mostWastedFoodItem = mostWasted?.key ?? 'Not enough data';
  }

  // Find the most common category of wasted foods (discarded more than once)
  String mostCommonCategory = 'Not enough data';
  if (categoryCounts.isNotEmpty) {
    // Only consider categories with more than one discarded item
    var mostCommon = categoryCounts.entries
        .where((entry) => entry.value > 1)  // Filter categories discarded more than once
        .fold<MapEntry<String, int>?>(
          null,
          (previous, current) {
            if (previous == null || current.value > previous.value) {
              return current;
            }
            return previous;
          },
        );

    mostCommonCategory = mostCommon?.key ?? 'Not enough data';
  }

  return UserStats(
    consumed: consumed,
    discarded: discarded,
    donated: donated,
    mostWastedFoodItem: mostWastedFoodItem,
    mostCommonCategory: mostCommonCategory,
    avgShelfLife: avgShelfLife,
  );
}


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserStats>(
      future: _userStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No user stats found.'));
        }

        UserStats stats = snapshot.data!;
        int total = stats.consumed + stats.discarded + stats.donated;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            double progress = _animationController.value; // Animation progress
            double consumedValue = stats.consumed * progress;
            double discardedValue = stats.discarded * progress;
            double donatedValue = stats.donated * progress;

            double consumedPercentage =
                total > 0 ? (consumedValue / total * 100) : 0;
            double discardedPercentage =
                total > 0 ? (discardedValue / total * 100) : 0;
            double donatedPercentage =
                total > 0 ? (donatedValue / total * 100) : 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Full-width card for aggregated Food Saved, Discarded, and Donated
                  FullWidthStatCard(
                    title: 'Food Stats',
                    value: '',
                    percentage: null,
                    color: Colors.blue,
                    child: Column(
                      children: [
                        Text(
                            'Food Saved: ${stats.consumed} (${consumedPercentage.toStringAsFixed(1)}%)',
                            style: TextStyle(color: Colors.green)),
                        Text(
                            'Food Discarded: ${stats.discarded} (${discardedPercentage.toStringAsFixed(1)}%)',
                            style: TextStyle(color: Colors.red)),
                        Text(
                            'Food Donated: ${stats.donated} (${donatedPercentage.toStringAsFixed(1)}%)',
                            style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Pie Chart for visualizing the percentages
                  Container(
                    height: 200,
                    child: PieChart(
                      fl_chart.PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: consumedPercentage,
                            color: Colors.green,
                            title: '${consumedPercentage.toStringAsFixed(1)}%',
                          ),
                          PieChartSectionData(
                            value: discardedPercentage,
                            color: Colors.red,
                            title: '${discardedPercentage.toStringAsFixed(1)}%',
                          ),
                          PieChartSectionData(
                            value: donatedPercentage,
                            color: Colors.blue,
                            title: '${donatedPercentage.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Other individual stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Most Wasted Food Item',
                          value: stats.mostWastedFoodItem,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Most Wasted Category',
                          value: stats.mostCommonCategory,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Average Shelf Life',
                          value:
                              '${stats.avgShelfLife.toStringAsFixed(2)} days',
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required dynamic value,
    required Color color,
  }) {
    return Card(
      elevation: 6, // Adding shadow for better depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // More rounded corners for a smoother look
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // Matching the card's rounded corners
          border: Border.all(color: color, width: 2), // Adding a border of the specified color
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // No colored box here
              Expanded(
                child: Text(
                  '$title: ${value.toString()}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


  Widget FullWidthStatCard({
    required String title,
    required dynamic value,
    double? percentage,
    required Color color,
    Widget? child,
  }) {
    return Card(
      elevation: 6, // Adding shadow for better depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            12), // More rounded corners for a smoother look
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(12), // Matching the card's rounded corners
          border: Border.all(
              color: color, width: 2), // Adding a border of the specified color
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child ??
              Row(
                children: [
                  // Add a colored box for the pie chart color only
                  if (percentage != null)
                    Container(
                      width: 16,
                      height: 16,
                      color: color,
                      margin: EdgeInsets.only(right: 8),
                    ),
                  Expanded(
                    child: Text(
                      '$title: ${value.toString()}${percentage != null ? ' (${percentage.toStringAsFixed(1)}%)' : ''}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }


class UserStats {
  final int consumed;
  final int discarded;
  final int donated;
  final String mostWastedFoodItem;
  final String mostCommonCategory;
  final double avgShelfLife;

  UserStats({
    required this.consumed,
    required this.discarded,
    required this.donated,
    required this.mostWastedFoodItem,
    required this.mostCommonCategory,
    required this.avgShelfLife,
  });
}
