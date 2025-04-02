import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shelfaware_app/models/user_stats.dart'; // Assuming you're using the pie_chart package
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shelfaware_app/services/my_stats_service.dart';

class MyStatsTab extends StatefulWidget {
  final String userId;
  const MyStatsTab({required this.userId, Key? key}) : super(key: key);
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
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: GestureDetector(
              onTap: () => _showMonthPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<UserStats>(
              future: _userStats,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Colors.blue),
                        SizedBox(height: 16),
                        Text(
                          'No user stats found for this month.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                UserStats stats = snapshot.data!;
                int total = stats.consumed + stats.discarded + stats.donated;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 170, // Reduced from 220
                                child: total == 0
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Lottie.network(
                                              'https://lottie.host/b6581299-f5e1-4e6f-84cb-856b088bcae4/YX0MBWmDwC.json',
                                              height: 120, // Reduced from 160
                                              width: 120, // Reduced from 160
                                              fit: BoxFit.cover,
                                            ),
                                            const Text(
                                              "No data for this month",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      )
                                    : AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (context, child) {
                                          return PieChart(
                                            PieChartData(
                                              borderData:
                                                  FlBorderData(show: false),
                                              sections: [
                                                PieChartSectionData(
                                                  value:
                                                      stats.consumed.toDouble(),
                                                  color: Colors.green.shade400,
                                                  title:
                                                      '${((stats.consumed / total) * 100).toStringAsFixed(0)}%',
                                                  radius: 50 *
                                                      _animationController
                                                          .value, // Animated radius
                                                  titleStyle: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  badgeWidget: _getSectionIcon(
                                                      Icons.check_circle,
                                                      Colors.white),
                                                  badgePositionPercentageOffset:
                                                      1.1,
                                                  showTitle:
                                                      _animationController
                                                              .value >
                                                          0.5,
                                                ),
                                                PieChartSectionData(
                                                  value: stats.discarded
                                                      .toDouble(),
                                                  color: Colors.redAccent,
                                                  title:
                                                      '${((stats.discarded / total) * 100).toStringAsFixed(0)}%',
                                                  radius: 50 *
                                                      _animationController
                                                          .value, // Animated radius
                                                  titleStyle: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  badgeWidget: _getSectionIcon(
                                                      Icons.delete,
                                                      Colors.white),
                                                  badgePositionPercentageOffset:
                                                      1.1,
                                                  showTitle:
                                                      _animationController
                                                              .value >
                                                          0.5,
                                                ),
                                                PieChartSectionData(
                                                  value:
                                                      stats.donated.toDouble(),
                                                  color: Colors.blueAccent,
                                                  title:
                                                      '${((stats.donated / total) * 100).toStringAsFixed(0)}%',
                                                  radius: 50 *
                                                      _animationController
                                                          .value, // Animated radius
                                                  titleStyle: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  badgeWidget: _getSectionIcon(
                                                      Icons.volunteer_activism,
                                                      Colors.white),
                                                  badgePositionPercentageOffset:
                                                      1.1,
                                                  showTitle:
                                                      _animationController
                                                              .value >
                                                          0.5,
                                                ),
                                              ],
                                              startDegreeOffset: 270 *
                                                  (1 -
                                                      _animationController
                                                          .value), // Rotate animation
                                              sectionsSpace: 2,
                                              centerSpaceRadius: 30,
                                              pieTouchData: PieTouchData(
                                                touchCallback:
                                                    (FlTouchEvent event,
                                                        PieTouchResponse?
                                                            response) {},
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              if (total > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0), // Reduced from 16
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildLegendItem(
                                          "Consumed",
                                          Colors.green.shade400,
                                          stats.consumed),
                                      _buildLegendItem("Discarded",
                                          Colors.redAccent, stats.discarded),
                                      _buildLegendItem("Donated",
                                          Colors.blueAccent, stats.donated),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12), // Reduced from 16
                      FutureBuilder<List<String>>(
                        future: _consumedItems,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data == null) {
                            return const SizedBox.shrink();
                          }
                          return _buildExpandableTile(
                              "Consumed",
                              Colors.green.shade400,
                              snapshot.data!,
                              Icons.check_circle);
                        },
                      ),
                      FutureBuilder<List<String>>(
                        future: _discardedItems,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data == null) {
                            return const SizedBox.shrink();
                          }
                          return _buildExpandableTile("Discarded",
                              Colors.redAccent, snapshot.data!, Icons.delete);
                        },
                      ),
                      FutureBuilder<List<String>>(
                        future: _donatedItems,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data == null) {
                            return const SizedBox.shrink();
                          }
                          return _buildExpandableTile(
                              "Donated",
                              Colors.blueAccent,
                              snapshot.data!,
                              Icons.volunteer_activism);
                        },
                      ),
                      const SizedBox(height: 16), // Reduced from 20
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSectionIcon(IconData icon, Color color) {
    return Container(
      width: 20, height: 20, // Reduced from 24
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)),
      child: Center(
          child: Icon(icon, color: color, size: 12)), // Size reduced from 16
    );
  }

  Widget _buildLegendItem(String title, Color color, int count) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10, height: 10, // Reduced from 12
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(title,
                style: const TextStyle(fontSize: 11)), // Reduced from 12
          ],
        ),
        const SizedBox(height: 2), // Reduced from 4
        Text(count.toString(),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)), // Reduced from 16
      ],
    );
  }

  Widget _buildExpandableTile(
      String category, Color color, List<String> items, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0), // Reduced from 8
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: color.withOpacity(0.2),
            colorScheme: ColorScheme.light(
              primary: color,
            ),
          ),
          child: ExpansionTile(
            leading: Icon(icon, color: color),
            title: Text(category,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: color),
              ],
            ),
            children: items.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No items found for this month",
                        style: TextStyle(color: color.withOpacity(0.7)),
                      ),
                    )
                  ]
                : items.map((item) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 2),
                      dense: true,
                      title: Text(
                        item[0].toUpperCase() + item.substring(1),
                        style: TextStyle(
                            fontSize: 14, color: color.withOpacity(0.8)),
                      ),
                      leading: Container(
                        width: 6,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3)),
                      ),
                    );
                  }).toList(),
          ),
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context) async {
    final DateTime? selectedDate = await showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null && selectedDate != _selectedDate) {
      setState(() {
        _selectedDate = selectedDate;
        _fetchStats();
      });
    }
  }
}
