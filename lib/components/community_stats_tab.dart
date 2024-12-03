import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:pie_chart/pie_chart.dart' as pie_chart;
// Assuming you're using the pie_chart package
// Assuming you're using the pie_chart package

class CommunityStatsTab extends StatefulWidget {
  @override
  _CommunityStatsTabState createState() => _CommunityStatsTabState();
}

class _CommunityStatsTabState extends State<CommunityStatsTab> {
  late Future<CommunityStats> _communityStats;

  @override
  void initState() {
    super.initState();
    _communityStats =
        fetchCommunityStats(); // Fetch community stats dynamically
  }

  // Fetch community stats from Firestore
  Future<CommunityStats> fetchCommunityStats() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('donations') // Assuming donations are in this collection
        .where('status',
            isEqualTo: 'completed') // Filter only completed donations
        .get();

    int totalDonations = 0;
    Map<String, bool> users = {}; // Track unique users who made donations

    for (var doc in snapshot.docs) {
      totalDonations++;

      // Track unique users who made donations
      String userId = doc[
          'userId']; // Assuming 'userId' is a field in the donation document
      users[userId] = true;
    }

    int activeUsers = users.length;

    return CommunityStats(
      totalDonations: totalDonations,
      activeUsers: activeUsers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CommunityStats>(
      future: _communityStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No community stats found.'));
        }

        CommunityStats stats = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title for the section

              SizedBox(height: 16),

              // PieChart for stats
              Container(
                height: 250, // Fixed height for the PieChart
                child: fl_chart.PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: stats.totalDonations.toDouble(),
                        color: Colors.blue,
                        title: 'Total Donations',
                        radius: 50,
                      ),
                      PieChartSectionData(
                        value: stats.activeUsers.toDouble(),
                        color: Colors.green,
                        title: 'Active Users',
                        radius: 50,
                      ),
                    ],
                    borderData:
                        FlBorderData(show: false), // Optional: removes border
                    sectionsSpace:
                        0, // Optional: adjusts space between sections
                    centerSpaceRadius:
                        30, // Optional: adjusts space in center of the chart
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '• Total Donations: ${stats.totalDonations}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                '• Active Users: ${stats.activeUsers}',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CommunityStats {
  final int totalDonations;
  final int activeUsers;

  CommunityStats({required this.totalDonations, required this.activeUsers});
}
