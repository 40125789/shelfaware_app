import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/notifiers/food_item_notifier.dart';
import 'package:shelfaware_app/components/food_items_bottom_sheet.dart'; // Import the FoodItemsBottomSheet component

class CalendarView extends ConsumerStatefulWidget {
  final String userId;

  const CalendarView(User user, {required this.userId, Key? key})
      : super(key: key);

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    ref.read(foodItemProvider.notifier).fetchFoodItems(widget.userId);
  }

  /// Get food items for a specific day
  List<Map<String, dynamic>> _getItemsForDay(DateTime day) {
    final foodItems = ref.watch(foodItemProvider);
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return foodItems.where((item) {
      final expiryTimestamp = item['expiryDate'] as Timestamp;
      final expiryDate = DateTime(
        expiryTimestamp.toDate().year,
        expiryTimestamp.toDate().month,
        expiryTimestamp.toDate().day,
      );
      return expiryDate == normalizedDay;
    }).toList();
  }

  /// Show a bottom sheet with the food items for the selected day
  void _showFoodItemsBottomSheet(DateTime selectedDate) {
    final items = _getItemsForDay(selectedDate);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FoodItemsBottomSheet(
          items: items,
          userId: widget.userId,
          selectedDate: selectedDate,
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
            _showFoodItemsBottomSheet(selectedDay);
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
