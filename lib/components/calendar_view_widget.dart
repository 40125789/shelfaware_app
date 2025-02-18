import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/services/food_item_service.dart';
import 'package:table_calendar/table_calendar.dart';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/services/food_item_service.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarView extends StatefulWidget {
  final String userId;

  const CalendarView(User user, {required this.userId, Key? key}) : super(key: key);

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _groupedFoodItems = {};
  final FoodItemService _foodService = FoodItemService();

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
  }

  /// Fetch food items from Firestore
  void _fetchFoodItems() async {
    try {
      Stream<List<DocumentSnapshot>> foodItemsStream =
          _foodService.getUserFoodItems(widget.userId);

      foodItemsStream.listen((snapshot) {
        Map<DateTime, List<Map<String, dynamic>>> groupedItems = {};

        for (var doc in snapshot) {
          final data = doc.data() as Map<String, dynamic>;
          Timestamp expiryTimestamp = data['expiryDate'];
          DateTime expiryDate = DateTime(
            expiryTimestamp.toDate().year,
            expiryTimestamp.toDate().month,
            expiryTimestamp.toDate().day,
          );

          if (groupedItems[expiryDate] == null) {
            groupedItems[expiryDate] = [];
          }
          groupedItems[expiryDate]!.add(data);
        }

        setState(() {
          _groupedFoodItems = groupedItems;
        });
      });
    } catch (e) {
      print('Error fetching food items: $e');
    }
  }

  /// Get food items for a specific day
  List<Map<String, dynamic>> _getItemsForDay(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return _groupedFoodItems[normalizedDay] ?? [];
  }

  /// Show a bottom sheet with the food items for the selected day
  void _showFoodItemsBottomSheet(List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Food Items Expiring',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item['productName'] ?? 'Unnamed Item'),
                      subtitle: Text('Quantity: ${item['quantity']}'),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });

            // Show the bottom sheet when a day is selected
            _showFoodItemsBottomSheet(_getItemsForDay(selectedDay));
          },
          eventLoader: _getItemsForDay,
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                // Display the number of expiring items as a small badge in the corner
                return Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${events.length}', // Display number of expiring items
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }
              return Container(); // No marker for days without events
            },
          ),
        ),
      ],
    );
  }
}