import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shelfaware_app/models/user_stats.dart'; // Assuming you're using the pie_chart package
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shelfaware_app/services/my_stats_service.dart';

class MyStatsTab extends StatefulWidget {
  final String userId;

  MyStatsTab({required this.userId});

  @override
  _MyStatsTabState createState() => _MyStatsTabState();
}

class _MyStatsTabState extends State<MyStatsTab> with TickerProviderStateMixin {
  final StatsService _statsService = StatsService();
  late Future<UserStats> _userStats;
  late Future<List<String>> _consumedItems;
  late Future<List<String>> _discardedItems;
  late Future<List<String>> _donatedItems;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    setState(() {
      _userStats = _statsService.getUserStats(widget.userId, _selectedDate);
      _consumedItems =
          _statsService.getConsumedItems(widget.userId, _selectedDate);
      _discardedItems =
          _statsService.getDiscardedItems(widget.userId, _selectedDate);
      _donatedItems =
          _statsService.getDonatedItems(widget.userId, _selectedDate);
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 12.0, vertical: 8.0), // Smaller padding
              decoration: BoxDecoration(
                color: Colors.green,
                
                
             
                borderRadius:
                    BorderRadius.circular(20), // Smaller border radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                DateFormat('MMMM').format(_selectedDate), // Show only the month
                style: TextStyle(
                  fontSize: 16, // Smaller font size
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
                      child: total == 0
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                Lottie.network(
                                'https://lottie.host/b6581299-f5e1-4e6f-84cb-856b088bcae4/YX0MBWmDwC.json',
                                height: 160,
                                width: 160,
                                fit: BoxFit.cover,
                                ),
                                ],
                              ),
                            )
                          : AnimatedSwitcher(
                              duration: Duration(seconds: 1),
                              child: PieChart(
                                key: ValueKey<int>(total),
                                PieChartData(
                                  borderData: FlBorderData(show: false),
                                  sections: [
                                    PieChartSectionData(
                                      value: (stats.consumed / total) * 100,
                                      color: Colors.green,
                                      title:
                                          '${((stats.consumed / total) * 100).toStringAsFixed(0)}%',
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
                                      title:
                                          '${((stats.discarded / total) * 100).toStringAsFixed(0)}%',
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
                                      title:
                                          '${((stats.donated / total) * 100).toStringAsFixed(0)}%',
                                      radius: 50,
                                      titleStyle: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      showTitle: true,
                                    ),
                                  ],
                                  // Add animation
                                  startDegreeOffset: 0,
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 40,
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event,
                                        PieTouchResponse? response) {},
                                  ),
                                ),
                                swapAnimationDuration: Duration(
                                    milliseconds: 800), // Animation duration
                                swapAnimationCurve:
                                    Curves.easeInOut, // Animation curve
                              ),
                            ),
                    ),
                    SizedBox(height: 10), // Reduced space between headers
                    FutureBuilder<List<String>>(
                      future: _consumedItems,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null) {
                          return Center(
                              child: Text('No consumed items found.'));
                        }

                        return _buildExpandableTile(
                            "Consumed Items", Colors.green, snapshot.data!);
                      },
                    ),
                    FutureBuilder<List<String>>(
                      future: _discardedItems,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null) {
                          return Center(
                              child: Text('No discarded items found.'));
                        }

                        return _buildExpandableTile(
                            "Discarded Items", Colors.red, snapshot.data!);
                      },
                    ),
                    FutureBuilder<List<String>>(
                      future: _donatedItems,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('No donated items found.'));
                        }

                        return _buildExpandableTile(
                            "Donated Items", Colors.blue, snapshot.data!);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableTile(
      String category, Color color, List<String> items) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4.0), // Reduced vertical padding
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
              title: Text(item[0].toUpperCase() + item.substring(1)),
              // subtitle: Text(item.updatedOn), // Added extra details
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Month picker (popup) function
  void _showMonthPicker(BuildContext context) async {
    DateTime? selectedDate = await showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
        _fetchStats();
      });
    }
  }
}
