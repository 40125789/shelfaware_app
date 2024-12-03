import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:pie_chart/pie_chart.dart'
    as pie_chart; // Assuming you're using the pie_chart package

class MyStatsTab extends StatefulWidget {
  final String userId; // Assume userId is passed

  MyStatsTab({required this.userId});

  @override
  _MyStatsTabState createState() => _MyStatsTabState();
}

class _MyStatsTabState extends State<MyStatsTab> {
  late Future<UserStats> _userStats;

  @override
  void initState() {
    super.initState();
    _userStats =
        fetchUserStats(widget.userId); // Fetch stats for a specific user
  }

  // Fetch user stats from Firestore
  Future<UserStats> fetchUserStats(String userId) async {
    var snapshot = await FirebaseFirestore.instance
        .collection(
            'history') // Assume history is the collection for food history
        .where('userId', isEqualTo: userId)
        .get();

    int consumed = 0;
    int discarded = 0;

    // Iterate over the documents and calculate consumed vs discarded food
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

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PieChart for stats
              Container(
                height: 250, // Fixed height for the PieChart
                child: fl_chart.PieChart(
                  fl_chart.PieChartData(
                    sections: [
                      fl_chart.PieChartSectionData(
                        value: stats.consumed.toDouble(),
                        color: Colors.green,
                        title: 'Food Saved',
                        radius: 50,
                      ),
                      fl_chart.PieChartSectionData(
                        value: stats.discarded.toDouble(),
                        color: Colors.red,
                        title: 'Food Discarded',
                        radius: 50,
                      ),
                    ],
                    borderData: fl_chart.FlBorderData(
                        show: false), // Optional: removes border
                    sectionsSpace:
                        0, // Optional: adjusts space between sections
                    centerSpaceRadius:
                        30, // Optional: adjusts space in center of the chart
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('• Food Saved: ${stats.consumed}',
                  style: TextStyle(fontSize: 18)),
              Text('• Food Discarded: ${stats.discarded}',
                  style: TextStyle(fontSize: 18)),
            ],
          ),
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
