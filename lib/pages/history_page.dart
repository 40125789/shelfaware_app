import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/food_history.dart';
import 'package:shelfaware_app/services/history_service.dart';

class HistoryPage extends StatefulWidget {
  final String userId; // Assuming the userId is passed to this page

  HistoryPage({required this.userId});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<FoodHistory>> _foodItems;

  @override
  void initState() {
    super.initState();
    _foodItems = HistoryService()
        .getHistoryItems(widget.userId); // Fetch the user's food items
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Item History'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<FoodHistory>>(
        future: _foodItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No food items found.'));
          }

          // Display the list of food items
          List<FoodHistory> foodItems = snapshot.data!;
          return ListView.builder(
            itemCount: foodItems.length,
            itemBuilder: (context, index) {
              final foodItem = foodItems[index];
              return ListTile(
                title: Text(foodItem.productName),
                subtitle: Text(
                    'Expiry: ${foodItem.expiryDate.toDate()} | Status: ${foodItem.status}'),
                trailing: Icon(Icons.more_vert),
                onTap: () {
                  // Navigate to the Mark Food Dialog (or other actions as needed)
                },
              );
            },
          );
        },
      ),
    );
  }
}
