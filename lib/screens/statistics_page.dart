import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/trends_tab.dart';
import 'package:shelfaware_app/components/my_stats_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // Get the current user's ID
  String? userId;


  @override
  void initState() {
    super.initState();
    // Retrieve the user ID from FirebaseAuth
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

 

 @override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      body: Column(
        children: [
          // Styled TabBar with padding and custom indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TabBar(
              indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 3.0,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Theme.of(context).primaryColor,
          ),
          insets: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              labelColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Theme.of(context).primaryColor,
              unselectedLabelColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[400] 
            : Colors.grey[700],
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              dividerColor: Colors.transparent,
              tabs: [
          Tab(text: 'Overview'),
          Tab(text: 'Trends'),
              ],
            ),
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
