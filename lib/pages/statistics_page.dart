import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/community_stats_tab.dart';
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
        appBar: AppBar(
          title: Text('Statistics'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'My Stats'),
              Tab(text: 'Community Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pass the userId to MyStatsTab
            MyStatsTab(userId: userId ?? ''),  // Ensure userId is not null
            CommunityStatsTab(),
          ],
        ),
      ),
    );
  }
}
