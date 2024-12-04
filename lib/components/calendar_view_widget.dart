import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
  }

  /// Fetch food items from Firestore and group by expiry date
  Future<void> _fetchFoodItems() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('foodItems')
          .where('userId', isEqualTo: widget.userId)
          .get();

      Map<DateTime, List<Map<String, dynamic>>> groupedItems = {};

      for (var doc in snapshot.docs) {
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
    } catch (e) {
      print('Error fetching food items: $e');
    }
  }

  /// Get food items for a specific day
  List<Map<String, dynamic>> _getItemsForDay(DateTime day) {
    return _groupedFoodItems[day] ?? [];
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
          },
          eventLoader: _getItemsForDay,
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _getItemsForDay(_selectedDay ?? DateTime.now()).isEmpty
              ? const Center(
                  child: Text(
                    "No food items expiring on this date.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _getItemsForDay(_selectedDay ?? DateTime.now()).length,
                  itemBuilder: (context, index) {
                    final item = _getItemsForDay(_selectedDay ?? DateTime.now())[index];
                    return ListTile(
                      title: Text(item['productName'] ?? 'Unnamed Item'),
                      subtitle: Text('Quantity: ${item['quantity']}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}