import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/services/trends_service.dart';
import 'package:shelfaware_app/repositories/trends_repository.dart';

class TrendsTab extends StatefulWidget {
  final String userId;

  TrendsTab({required this.userId});

  @override
  _TrendsTabState createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  late Future<Map<String, dynamic>> trendsFuture;
  late Future<String> joinDurationFuture;
  late TrendsService trendsService;

  @override
  void initState() {
    super.initState();
    TrendsRepository trendsRepository = TrendsRepository(auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance);
    trendsService = TrendsService(trendsRepository);
    trendsFuture = trendsService.fetchTrends(widget.userId);
    joinDurationFuture = trendsService.fetchJoinDuration(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: trendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.containsKey("error")) {
            return Center(
                child:
                    Text(snapshot.data?["error"] ?? 'No insights available.'));
          }

          var foodInsights = snapshot.data!["foodInsights"];
          var donationStats = snapshot.data!["donationStats"];

          int totalDonations = donationStats["givenDonations"] +
              donationStats["receivedDonations"];

          return FutureBuilder<String>(
            future: joinDurationFuture,
            builder: (context, joinSnapshot) {
              if (joinSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (joinSnapshot.hasError) {
                return Center(child: Text('Error: ${joinSnapshot.error}'));
              }

              String joinDuration = joinSnapshot.data ?? "Unknown duration";

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          text: "$joinDuration",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                          children: <TextSpan>[
                            TextSpan(
                              text: " since you've joined!",
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text('Food Trends',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          _buildCard('Top Wasted Item',
                              foodInsights["mostWastedFoodItem"], '🚯'),
                          _buildCard('Top Wasted Category',
                              foodInsights["mostWastedFoodCategory"], '🔖'),
                          _buildCard('Top Discard Reason',
                              foodInsights["mostCommonDiscardReason"], '🚮'),
                          _buildCard(
                              'Average Discard Rate',
                              foodInsights[
                                  "averageTimeBetweenAddingAndDiscarding"],
                              '⏰'),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text('Donation Trends',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      _buildProgressBar(
                          'Donations Given',
                          donationStats["givenDonations"],
                          totalDonations,
                          Colors.blue),
                      SizedBox(height: 8),
                      _buildProgressBar(
                          'Donations Received',
                          donationStats["receivedDonations"],
                          totalDonations,
                          Colors.green),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCard(String title, String value, String emoji) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                emoji,
                style: TextStyle(fontSize: 24),
              ),
            ),
            SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String title, int value, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: total > 0 ? value / total : 0,
          backgroundColor: color.withOpacity(0.2),
          color: color,
          minHeight: 20,
        ),
        SizedBox(height: 8),
        Text('$value', style: TextStyle(fontSize: 14)),
      ],
    );
  }
}