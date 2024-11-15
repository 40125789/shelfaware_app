import 'package:flutter/material.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats(); // Simulate loading stats
  }

  Future<void> _loadStats() async {
    // Simulate a delay for loading stats
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'My Stats'),
            Tab(text: 'Community Stats'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : TabBarView(
              controller: _tabController,
              children: [
                MyStatsTab(), // Widget for "My Stats"
                CommunityStatsTab(), // Widget for "Community Stats"
              ],
            ),
    );
  }
}

class MyStatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace with actual stats for the logged-in user
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'My Stats',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            '• Items Donated: 12',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            '• Waste Reduced: 5 kg',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            '• Environmental Impact: Positive 🌱',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class CommunityStatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace with actual aggregated community stats
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Community Stats',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            '• Total Donations: 250',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            '• Food Waste Prevented: 1,200 kg',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            '• Active Users: 150',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
