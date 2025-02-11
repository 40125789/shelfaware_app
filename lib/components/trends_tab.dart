import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/firebase_service.dart';

class TrendsTab extends StatefulWidget {
  final String userId;

  TrendsTab({required this.userId});

  @override
  _TrendsTabState createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  late Future<Map<String, dynamic>> trendsFuture;
  late Future<String> joinDurationFuture;

  @override
  void initState() {
    super.initState();
    trendsFuture = _fetchTrends(widget.userId);
    joinDurationFuture = _fetchJoinDuration(widget.userId);
  }

  Future<Map<String, dynamic>> _fetchTrends(String userId) async {
    FirebaseService firebaseService = FirebaseService();
    DonationService donationService = DonationService();

    // Fetch history data from Firebase
    List<Map<String, dynamic>> historyData;
    try {
      historyData = await firebaseService.getHistoryData(userId);
    } catch (e) {
      return {"error": "Error fetching history data: $e"};
    }

    // Fetch donation stats from Firebase
    List<Map<String, dynamic>> donations = [];
    try {
      var donationDataStream = donationService.getAllDonations();
      var donationData = await donationDataStream.first;
      if (donationData != null) {
        donations = List<Map<String, dynamic>>.from(donationData);
      }
    } catch (e) {
      return {"error": "Error fetching donations: $e"};
    }

    if (historyData.isEmpty && donations.isEmpty) {
      return {"error": "No data found."};
    }

    // Analyze history data
    Map<String, dynamic> foodInsights = _analyzeHistoryData(historyData);

    // Analyze donation stats
    Map<String, dynamic> donationStats =
        _analyzeDonationStats(donations, userId);

    return {
      "foodInsights": foodInsights,
      "donationStats": donationStats,
    };
  }

  Future<String> _fetchJoinDuration(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return "Unknown duration";
    }

    Timestamp joinDate = userDoc['joinDate'];
    Duration duration = DateTime.now().difference(joinDate.toDate());

    if (duration.inDays > 0) {
      return "${duration.inDays} days";
    } else {
      return "${duration.inHours} hours";
    }
  }

  Map<String, dynamic> _analyzeHistoryData(
      List<Map<String, dynamic>> historyData) {
    // Example analysis logic
    Map<String, int> foodItemCount = {};
    Map<String, int> foodCategoryCount = {};
    Map<String, int> discardReasonCount = {};
    int totalDiscardedItems = 0;
    Duration totalTimeBetweenAddingAndDiscarding = Duration.zero;

    for (var item in historyData) {
      String? foodItem = item['productName'];
      String? foodCategory = item['category'];
      String? reason = item['reason'];
      Timestamp? addedOn = item['addedOn'];
      Timestamp? discardedOn = item['updatedOn'];
      String? status = item['status'];

      // Only consider discarded items
      if (status == 'discarded' && addedOn != null && discardedOn != null) {
        // Count food items
        if (foodItem != null) {
          if (foodItemCount.containsKey(foodItem)) {
            foodItemCount[foodItem] = foodItemCount[foodItem]! + 1;
          } else {
            foodItemCount[foodItem] = 1;
          }
        }

        // Count food categories
        if (foodCategory != null) {
          if (foodCategoryCount.containsKey(foodCategory)) {
            foodCategoryCount[foodCategory] =
                foodCategoryCount[foodCategory]! + 1;
          } else {
            foodCategoryCount[foodCategory] = 1;
          }
        }

        // Count discard reasons
        if (reason != null) {
          if (discardReasonCount.containsKey(reason)) {
            discardReasonCount[reason] = discardReasonCount[reason]! + 1;
          } else {
            discardReasonCount[reason] = 1;
          }
        }

        // Calculate total discarded items
        totalDiscardedItems++;

        // Calculate total time between adding and discarding
        totalTimeBetweenAddingAndDiscarding +=
            discardedOn.toDate().difference(addedOn.toDate());
      }
    }

    // Find most wasted food item and category
    String mostWastedFoodItem = foodItemCount.isNotEmpty
        ? foodItemCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'No data';
    String mostWastedFoodCategory = foodCategoryCount.isNotEmpty
        ? foodCategoryCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 'No data';

    // Find most common discard reason
    String mostCommonDiscardReason = discardReasonCount.isNotEmpty
        ? discardReasonCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 'No data';

    // Calculate average time between adding and discarding
    Duration averageTimeBetweenAddingAndDiscarding = totalDiscardedItems > 0
        ? totalTimeBetweenAddingAndDiscarding ~/ totalDiscardedItems
        : Duration.zero;

    // Format the average time between adding and discarding
    String formattedAverageTime =
        _formatDuration(averageTimeBetweenAddingAndDiscarding);

    return {
      "mostWastedFoodItem": mostWastedFoodItem,
      "mostWastedFoodCategory": mostWastedFoodCategory,
      "mostCommonDiscardReason": mostCommonDiscardReason,
      "averageTimeBetweenAddingAndDiscarding": formattedAverageTime,
    };
  }

  String _formatDuration(Duration duration) {
    int days = duration.inDays;
    int hours = duration.inHours % 24;
    if (days > 0) {
      return "$days days after adding";
    } else {
      return "$hours hours after adding";
    }
  }

  Map<String, dynamic> _analyzeDonationStats(
      List<Map<String, dynamic>> donations, String userId) {
    int givenDonations = 0;
    int receivedDonations = 0;

    for (var donation in donations) {
      if (donation['donorId'] == userId && donation['status'] == 'Picked Up') {
        givenDonations++;
      }
      if (donation['assignedTo'] == userId &&
          donation['status'] == 'Picked Up') {
        receivedDonations++;
      }
    }

    return {
      "givenDonations": givenDonations,
      "receivedDonations": receivedDonations,
    };
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
                              style: TextStyle(color: Colors.black),
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
      color: Colors.white,
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
