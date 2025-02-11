import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/trends_tab.dart';
import 'package:shelfaware_app/components/my_stats_tab.dart';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // Get the current user's ID
  String? userId;
  bool isWeekly = true;  // Default to weekly

  @override
  void initState() {
    super.initState();
    // Retrieve the user ID from FirebaseAuth
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  // Toggle view between weekly and monthly
  void _toggleView(bool value) {
    setState(() {
      isWeekly = value;
    });
  }

 @override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      body: Column(
        children: [
          // Directly add TabBar in the body instead of AppBar
          TabBar(
            tabs: [
              Tab(text: 'Overview'),  // Change the tab text
              Tab(text: 'Trends'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Pass the userId to MyStatsTab
                MyStatsTab(userId: userId ?? ''),  // Ensure userId is not null
                TrendsTab(userId: userId ?? '',), // Trends Tab with toggle
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
