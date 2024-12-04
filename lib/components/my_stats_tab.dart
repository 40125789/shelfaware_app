import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:pie_chart/pie_chart.dart'
    as pie_chart;
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

    for (var doc in snapshot.docs) {
      String status = doc['status'] ?? '';
      if (status == 'consumed') {
        consumed++;
      } else if (status == 'discarded') {
        discarded++;
      }
    }

    return UserStats(consumed: consumed, discarded: discarded);
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
        int total = stats.consumed + stats.discarded;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            double progress = _animationController.value; // Animation progress
            double consumedValue = stats.consumed * progress;
            double discardedValue = stats.discarded * progress;

            double consumedPercentage =
                total > 0 ? (consumedValue / total * 100) : 0;
            double discardedPercentage =
                total > 0 ? (discardedValue / total * 100) : 0;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pie Chart with progressive animation
                  Container(
                    height: 250,
                    child: fl_chart.PieChart(
                      fl_chart.PieChartData(
                        sections: [
                          fl_chart.PieChartSectionData(
                            value: consumedValue,
                            color: Colors.green,
                            title:
                                '${consumedPercentage.toStringAsFixed(1)}%', // Animated label
                            radius: 50,
                            titleStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          fl_chart.PieChartSectionData(
                            value: discardedValue,
                            color: Colors.red,
                            title:
                                '${discardedPercentage.toStringAsFixed(1)}%', // Animated label
                            radius: 50,
                            titleStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        borderData: fl_chart.FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        color: Colors.green,
                        margin: EdgeInsets.only(right: 8),
                      ),
                      Text(
                        'Food Saved: ${stats.consumed} (${consumedPercentage.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        color: Colors.red,
                        margin: EdgeInsets.only(right: 8),
                      ),
                      Text(
                        'Food Discarded: ${stats.discarded} (${discardedPercentage.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 18),
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
}

class UserStats {
  final int consumed;
  final int discarded;

  UserStats({required this.consumed, required this.discarded});
}
