import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:pie_chart/pie_chart.dart' as pie_chart;
import 'package:shelfaware_app/components/additional_stats_widget.dart';
import 'package:shelfaware_app/models/user_stats.dart'; // Assuming you're using the pie_chart package

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
  late Animation<double> _consumedAnimation;
  late Animation<double> _discardedAnimation;
  late Animation<double> _donatedAnimation;

  @override
  void initState() {
    super.initState();
    _userStats = fetchUserStats(widget.userId);

    // Initialize AnimationController
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Create individual animations for each section of the pie chart
    _consumedAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.0, 0.33, curve: Curves.easeInOut)),
    );

    _discardedAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.33, 0.66, curve: Curves.easeInOut)),
    );

    _donatedAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.66, 1.0, curve: Curves.easeInOut)),
    );

    _animationController.forward(); // Start the animation
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
        wastedFoodItems[foodName] = (wastedFoodItems[foodName] ?? 0) + 1;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        int shelfLife = updatedDate.difference(addedDate).inDays;
        shelfLifeDifferences.add(shelfLife);
      }
    }

    var donationSnapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Taken')
        .get();

    int donated = donationSnapshot.docs.length;

    double avgShelfLife = 0;
    if (shelfLifeDifferences.isNotEmpty) {
      avgShelfLife = shelfLifeDifferences.reduce((a, b) => a + b) /
          shelfLifeDifferences.length;
    }

    String mostWastedFoodItem = 'Not enough data';
    if (wastedFoodItems.isNotEmpty) {
      var mostWasted = wastedFoodItems.entries
          .where((entry) => entry.value > 1)
          .fold<MapEntry<String, int>?>(null, (previous, current) {
        if (previous == null || current.value > previous.value) {
          return current;
        }
        return previous;
      });

      mostWastedFoodItem = mostWasted?.key ?? 'Not enough data';
    }

    String mostCommonCategory = 'Not enough data';
    if (categoryCounts.isNotEmpty) {
      var mostCommon = categoryCounts.entries
          .where((entry) => entry.value > 1)
          .fold<MapEntry<String, int>?>(null, (previous, current) {
        if (previous == null || current.value > previous.value) {
          return current;
        }
        return previous;
      });

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
            double consumedValue = stats.consumed * _consumedAnimation.value;
            double discardedValue = stats.discarded * _discardedAnimation.value;
            double donatedValue = stats.donated * _donatedAnimation.value;

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
                  // Pie Chart for visualizing the percentages
                  Container(
                    height: 200,
                    child: PieChart(
                      fl_chart.PieChartData(
                        sectionsSpace: 0,
                        borderData: FlBorderData(show: false),
                        sections: [
                          PieChartSectionData(
                            value: consumedPercentage,
                            color: Colors.green,
                            title: '${consumedPercentage.toStringAsFixed(1)}%',
                            radius: 50,
                            titleStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            showTitle: true,
                          ),
                          PieChartSectionData(
                            value: discardedPercentage,
                            color: Colors.red,
                            title: '${discardedPercentage.toStringAsFixed(1)}%',
                            radius: 50,
                            titleStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            showTitle: true,
                          ),
                          PieChartSectionData(
                            value: donatedPercentage,
                            color: Colors.blue,
                            title: '${donatedPercentage.toStringAsFixed(1)}%',
                            radius: 50,
                            titleStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            showTitle: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
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
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              // Add a colored box for the value
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: color,
                    margin: EdgeInsets.only(right: 8),
                  ),
                  Text(
                    value.toString(),
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black), // Ensuring text is black
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  // Add squares for the labels with black text
                  Row(
                    children: [
                      _buildColorBox(Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Food Saved: ${value.toString()} (${percentage?.toStringAsFixed(1)}%)',
                        style: TextStyle(
                            color: Colors.black), // Keeping text black
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildColorBox(Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Food Discarded: ${value.toString()} (${percentage?.toStringAsFixed(1)}%)',
                        style: TextStyle(
                            color: Colors.black), // Ensuring black text color
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildColorBox(Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Food Donated: ${value.toString()} (${percentage?.toStringAsFixed(1)}%)',
                        style: TextStyle(
                            color: Colors.black), // Text color remains black
                      ),
                    ],
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildColorBox(Color color) {
    return Container(
      width: 16,
      height: 16,
      color: color,
      margin: EdgeInsets.symmetric(
          vertical: 4), // Added vertical margin to ensure separation
    );
  }
}
