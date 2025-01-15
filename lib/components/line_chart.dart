import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LineChartWidget extends StatelessWidget {
  final bool isWeekly;
  final LineChartData lineChartData;
  final String userId;

  LineChartWidget({required this.isWeekly, required this.lineChartData, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      height: 300,
      child: LineChart(lineChartData),
    );
  }
}

Future<Map<String, List<FlSpot>>> getFoodData(String userId, DateTime startDate, DateTime endDate, bool isWeekly) async {
  Timestamp startTimestamp = Timestamp.fromDate(startDate);
  Timestamp endTimestamp = Timestamp.fromDate(endDate);

  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('history')
      .where('userId', isEqualTo: userId)
      .where('updatedOn', isGreaterThanOrEqualTo: startTimestamp)
      .where('updatedOn', isLessThanOrEqualTo: endTimestamp)
      .get();

  // Maps for aggregated data
  Map<int, int> consumedData = {}; // Key: Time period (week/month index), Value: Count
  Map<int, int> discardedData = {}; // Key: Time period (week/month index), Value: Count

  // Check if any documents were returned
  if (snapshot.docs.isEmpty) {
    print('No documents found for user $userId in the specified date range.');
  }

  for (var doc in snapshot.docs) {
    String status = doc['status'];
    DateTime updatedOn = (doc['updatedOn'] as Timestamp).toDate();

    int periodIndex; // Week or month index
    if (isWeekly) {
      periodIndex = (updatedOn.difference(startDate).inDays ~/ 7); // Weeks since start date
    } else {
      periodIndex = updatedOn.month; // Month index (1–12)
    }

    // Aggregate data based on the status and period index
    if (status == 'consumed') {
      consumedData[periodIndex] = (consumedData[periodIndex] ?? 0) + 1;
    } else if (status == 'discarded') {
      discardedData[periodIndex] = (discardedData[periodIndex] ?? 0) + 1;
    }
  }

  // Convert data to FlSpot format
  List<FlSpot> consumedSpots = consumedData.entries
      .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
      .toList();

  List<FlSpot> discardedSpots = discardedData.entries
      .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
      .toList();

  // Debugging: Print the results
  print('Consumed Spots: $consumedSpots');
  print('Discarded Spots: $discardedSpots');

  // Return the data
  return {
    'consumed': consumedSpots,
    'discarded': discardedSpots,
  };
}

Future<LineChartData> getWeeklyLineChartData(String userId) async {
  DateTime now = DateTime.now();
  DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Start of the week (Monday)
  DateTime endOfWeek = startOfWeek.add(Duration(days: 6)); // End of the week (Sunday)

  Map<String, List<FlSpot>> foodData = await getFoodData(userId, startOfWeek, endOfWeek, true);

  // Ensure that data exists for both "consumed" and "discarded"
  if (foodData['consumed']!.isEmpty && foodData['discarded']!.isEmpty) {
    // Handle the case where no data is available for both categories
    print('No data available for consumed or discarded items.');
  }

  // Calculate the maxY value for scaling the Y-axis correctly
  double maxY = 0;
  if (foodData['consumed']!.isNotEmpty) {
    maxY = foodData['consumed']!.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
  }
  if (foodData['discarded']!.isNotEmpty) {
    maxY = maxY > foodData['discarded']!.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) ? maxY : foodData['discarded']!.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
  }

  // Create a list of weekly labels (e.g., "Week 1", "Week 2")
  List<String> weekLabels = List.generate(12, (index) => 'Week ${index + 1}');

  return LineChartData(
    gridData: FlGridData(show: true),
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            int weekNumber = value.toInt(); // Show the corresponding week label
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                weekLabels[weekNumber % weekLabels.length], // Map the week number to a label
                style: TextStyle(fontSize: 8),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    borderData: FlBorderData(show: true),
    minX: 0, // Start of the week
    maxX: 11, // Total number of weeks in the range (12 weeks max)
    minY: 0,
    maxY: maxY + 1, // Set maxY based on the data
    lineBarsData: [
      if (foodData['consumed']!.isNotEmpty) 
        LineChartBarData(
          spots: foodData['consumed']!,
          isCurved: true,
          color: Colors.green,
          barWidth: 4,
          belowBarData: BarAreaData(show: false),
          aboveBarData: BarAreaData(show: false),
        ),
      if (foodData['discarded']!.isNotEmpty)
        LineChartBarData(
          spots: foodData['discarded']!,
          isCurved: true,
          color: Colors.red,
          barWidth: 4,
          belowBarData: BarAreaData(show: false),
          aboveBarData: BarAreaData(show: false),
        ),
    ],
  );
}


Future<LineChartData> getMonthlyLineChartData(String userId) async {
  DateTime now = DateTime.now();
  DateTime startOfYear = DateTime(now.year, 1, 1);
  DateTime endOfYear = DateTime(now.year, 12, 31);

  Map<String, List<FlSpot>> foodData = await getFoodData(userId, startOfYear, endOfYear, false);

  return LineChartData(
    gridData: FlGridData(show: true),
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1, // Show every month
          getTitlesWidget: (value, meta) {
            // Display abbreviated month names (Jan, Feb, etc.)
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // Even padding on both sides
              child: Text(
                DateFormat.MMM().format(DateTime(0, value.toInt())),
                style: TextStyle(fontSize: 8), // Smaller font size for better fit
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false), // Hide top titles
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false), // Hide right titles
      ),
    ),
    borderData: FlBorderData(show: true),
    minX: 1,
    maxX: 12, // Monthly range (1-12 for January to December)
    minY: 0,
    maxY: foodData['consumed']!
        .map((spot) => spot.y)
        .followedBy(foodData['discarded']!.map((spot) => spot.y))
        .reduce((a, b) => a > b ? a : b),
    lineBarsData: [
      LineChartBarData(
        spots: foodData['consumed']!,
        isCurved: true,
        color: Colors.green,
        barWidth: 4,
      ),
      LineChartBarData(
        spots: foodData['discarded']!,
        isCurved: true,
        color: Colors.red,
        barWidth: 4,
      ),
    ],
  );
}
