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
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Increased padding
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: theme.primaryColor),
                rightChevronIcon: Icon(Icons.chevron_right, color: theme.primaryColor),
              ),
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
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red[400]),
                holidayTextStyle: TextStyle(color: Colors.red[400]),
                todayDecoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red[600],
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '${events.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              rowHeight: 45, // Explicitly set row height
              daysOfWeekHeight: 20, // Explicitly set days of week row height
            ),
            const SizedBox(height: 8), // Added bottom spacing
          ],
        ),
      ),
    ),
    );
    
  }
}

