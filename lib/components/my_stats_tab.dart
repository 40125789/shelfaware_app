import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart' as pie_chart;
import 'package:shelfaware_app/components/additional_stats_widget.dart';
import 'package:shelfaware_app/models/user_stats.dart'; // Assuming you're using the pie_chart package

import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyStatsTab extends StatefulWidget {
  final String userId;

  MyStatsTab({required this.userId});

  @override
  _MyStatsTabState createState() => _MyStatsTabState();
}

class _MyStatsTabState extends State<MyStatsTab> with TickerProviderStateMixin {
  late Future<UserStats> _userStats;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  List<String> _consumedItems = [];
  List<String> _discardedItems = [];
  List<String> _donatedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    setState(() {
      _userStats = fetchUserStats(widget.userId, _selectedMonth);
      _fetchFoodItems();
      _fetchDonatedItems();
    });
  }

  Future<UserStats> fetchUserStats(String userId, String month) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: userId)
        .get();

    int consumed = 0;
    int discarded = 0;
    int donated = 0;

    for (var doc in snapshot.docs) {
      DateTime addedDate = (doc['updatedOn'] as Timestamp).toDate();
      if (DateFormat('MMMM').format(addedDate) != month) continue;

      String status = doc['status'] ?? '';
      if (status == 'consumed') {
        consumed++;
      } else if (status == 'discarded') {
        discarded++;
      }
    }

    var donationSnapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Taken')
        .get();

    for (var doc in donationSnapshot.docs) {
      DateTime donationDate = (doc['addedOn'] as Timestamp).toDate();
      if (DateFormat('MMMM').format(donationDate) == month) {
        donated++;
      }
    }

    return UserStats(
      consumed: consumed,
      discarded: discarded,
      donated: donated,
      mostWastedFoodItem: '',
      mostCommonCategory: '',
      avgShelfLife: 0,
    );
  }

  // Fetch consumed and discarded food items
  void _fetchFoodItems() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: widget.userId)
        .get();

    List<String> consumedItems = [];
    List<String> discardedItems = [];

    for (var doc in snapshot.docs) {
      DateTime addedDate = (doc['updatedOn'] as Timestamp).toDate();
      if (DateFormat('MMMM').format(addedDate) != _selectedMonth) continue;

      String status = doc['status'] ?? '';
      String foodName = doc['productName'] ?? '';

      if (status == 'consumed') {
        consumedItems.add(foodName);
      } else if (status == 'discarded') {
        discardedItems.add(foodName);
      }
    }

    setState(() {
      _consumedItems = consumedItems;
      _discardedItems = discardedItems;
    });
  }

  // Fetch donated food items
  void _fetchDonatedItems() async {
    var donationSnapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('userId', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'Taken')
        .get();

    List<String> donatedItems = [];

    for (var doc in donationSnapshot.docs) {
      DateTime donationDate = (doc['addedOn'] as Timestamp).toDate();
      if (DateFormat('MMMM').format(donationDate) == _selectedMonth) {
        String foodName = doc['productName'] ?? '';
        donatedItems.add(foodName);
      }
    }

    setState(() {
      _donatedItems = donatedItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,  
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                _selectedMonth,
                style: TextStyle(
                  fontSize: 20,
              
              
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<UserStats>(
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

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      child: AnimatedSwitcher(
                        duration: Duration(seconds: 1),
                        child: PieChart(
                          key: ValueKey<int>(total),
                          PieChartData(
                            sectionsSpace: 0,
                            borderData: FlBorderData(show: false),
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                value: (stats.consumed / total) * 100,
                                color: Colors.green,
                                title: '${((stats.consumed / total) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                showTitle: true,
                              ),
                              PieChartSectionData(
                                value: (stats.discarded / total) * 100,
                                color: Colors.red,
                                title: '${((stats.discarded / total) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                showTitle: true,
                              ),
                              PieChartSectionData(
                                value: (stats.donated / total) * 100,
                                color: Colors.blue,
                                title: '${((stats.donated / total) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                showTitle: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10), // Reduced space between headers
                    _buildExpandableTile("Consumed Items", Colors.green, _consumedItems),
                    _buildExpandableTile("Discarded Items", Colors.red, _discardedItems),
                    _buildExpandableTile("Donated Items", Colors.blue, _donatedItems),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableTile(String category, Color color, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Reduced vertical padding
      child: ExpansionTile(
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '(${items.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        children: items.map((item) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(item),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Month picker (popup) function
  void _showMonthPicker(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _selectedMonth = DateFormat('MMMM').format(selectedDate);
        _fetchStats();
      });
    }
  }
}



class UserStats {
  final int consumed;
  final int discarded;
  final int donated;
  final String mostWastedFoodItem;
  final String mostCommonCategory;
  final double avgShelfLife;

  UserStats({
    required this.consumed,
    required this.discarded,
    required this.donated,
    required this.mostWastedFoodItem,
    required this.mostCommonCategory,
    required this.avgShelfLife,
  });
}
