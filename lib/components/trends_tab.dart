import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:shelfaware_app/components/line_chart.dart' as custom;
import 'package:shelfaware_app/components/line_chart.dart';
import 'package:shelfaware_app/components/card_tiles.dart';
// Assuming you're using the pie_chart package

class TrendsTab extends StatelessWidget {
  final bool isWeekly;
  final Function(bool) onToggle;
  final String userId;

  TrendsTab(
      {required this.isWeekly, required this.onToggle, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LineChartData>(
      future: isWeekly
          ? getWeeklyLineChartData(userId)
          : getMonthlyLineChartData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data != null) {
          LineChartData lineChartData = snapshot.data!;
          print("lineChartData: $lineChartData");

          // Proceed if there is enough data, otherwise handle it gracefully
          Map<String, dynamic> highestFoodWaste =
              lineChartData.lineBarsData.length > 1
                  ? getHighestWeekOrMonth(lineChartData.lineBarsData[1].spots,
                      isWeekly ? 'weekly' : 'monthly')
                  : {
                      'period': isWeekly ? 'weekly' : 'monthly',
                      'value': 0,
                      'spot': FlSpot(0, 0)
                    };

          Map<String, dynamic> highestFoodSaved =
              lineChartData.lineBarsData.length > 1
                  ? getHighestWeekOrMonth(lineChartData.lineBarsData[0].spots,
                      isWeekly ? 'weekly' : 'monthly')
                  : {
                      'period': isWeekly ? 'weekly' : 'monthly',
                      'value': 0,
                      'spot': FlSpot(0, 0)
                    };

          print("highestFoodWaste: $highestFoodWaste");
          print("highestFoodSaved: $highestFoodSaved");

          return Column(
            children: [
       Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Weekly Button
    Padding(
      padding: const EdgeInsets.all(8.0), // Adds padding around the button
      child: GestureDetector(
        onTap: () => onToggle(true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Animation duration
          curve: Curves.easeInOut, // Smooth animation
          decoration: BoxDecoration(
            color: isWeekly ? Colors.green : Colors.grey.shade300, // Background color
            borderRadius: BorderRadius.circular(8), // Rounded corners
            boxShadow: [
              if (isWeekly) // Add shadow only if selected
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Internal padding
          child: Text(
            "Weekly",
            style: TextStyle(
              color: isWeekly ? Colors.white : Colors.black, // Text color
              fontWeight: isWeekly ? FontWeight.bold : FontWeight.normal, // Bold for selected
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
    // Monthly Button
    Padding(
      padding: const EdgeInsets.all(8.0), // Adds padding around the button
      child: GestureDetector(
        onTap: () => onToggle(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Animation duration
          curve: Curves.easeInOut, // Smooth animation
          decoration: BoxDecoration(
            color: !isWeekly ? Colors.green : Colors.grey.shade300, // Background color
            borderRadius: BorderRadius.circular(8), // Rounded corners
            boxShadow: [
              if (!isWeekly) // Add shadow only if selected
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Internal padding
          child: Text(
            "Monthly",
            style: TextStyle(
              color: !isWeekly ? Colors.white : Colors.black, // Text color
              fontWeight: !isWeekly ? FontWeight.bold : FontWeight.normal, // Bold for selected
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
  ],
),
              
              SizedBox(height: 8),
              Container(
                height: 250,
                child: LineChartWidget(
                  isWeekly: isWeekly,
                  lineChartData: lineChartData,
                  userId: userId,
                ),
              ),
              Expanded(
                child: CardTiles(
                  isWeekly: isWeekly,
                  highestFoodWaste: highestFoodWaste,
                  highestFoodSaved: highestFoodSaved,
                ),
              ),
            ],
          );
        } else {
          return Center(
              child: Text('No trends data available for this period.'));
        }
      },
    );
  }

  Map<String, dynamic> getHighestWeekOrMonth(
      List<FlSpot> spots, String period) {
    if (spots.isEmpty) {
      return {
        'period': period,
        'value': 0,
        'spot': FlSpot(0, 0)
      }; // Default values if no spots exist
    }

    double highestValue =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    FlSpot highestSpot = spots.firstWhere((spot) => spot.y == highestValue);

    // Convert the x-axis value to a month name (1 = January, 2 = February, etc.)
    String periodLabel = period == 'weekly'
        ? 'Week ${highestSpot.x.toInt()}'
        : monthNameFromNumber(
            highestSpot.x.toInt()); // Get month name from number

    return {
      'period': periodLabel,
      'value': highestValue,
      'spot': highestSpot,
    };
  }

// Helper function to convert a month number to the month name
  String monthNameFromNumber(int monthNumber) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[monthNumber - 1]; // Adjust for 1-indexed months
  }
}
