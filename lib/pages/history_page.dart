import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/models/food_history.dart';
import 'package:shelfaware_app/pages/add_food_item.dart';
import 'package:shelfaware_app/services/history_service.dart';

class HistoryPage extends StatefulWidget {
  final String userId;

  HistoryPage({required this.userId});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<FoodHistory>> _foodItems;
  List<int> _selectedItems = []; // Track selected food items
  bool _isRecreateMode = false; // Flag for toggling recreate mode

  @override
  void initState() {
    super.initState();
    _foodItems = HistoryService().getHistoryItems(widget.userId);
  }

  // Handle the Recreate button press
  void _onRecreateSelected(List<FoodHistory> selectedFoodItems) {
    if (selectedFoodItems.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddFoodItem(
            foodItem: selectedFoodItems.first,
            isRecreated: true, foodItems: [],
            // Pass selected items to AddFoodItem
          ),
        ),
      );
    } else {
      // Show an error message if no items are selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one food item to recreate.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to toggle recreate mode and clear selection
  void _toggleRecreateMode() {
    setState(() {
      _isRecreateMode = !_isRecreateMode;
      if (!_isRecreateMode) {
        _selectedItems.clear(); // Clear selection when exiting recreate mode
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isRecreateMode
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  // Exit recreate mode by setting _isRecreateMode to false
                  _toggleRecreateMode();
                },
              )
            : null, // Show back button only when in recreate mode

        title: _isRecreateMode
            ? Text(
                '${_selectedItems.length} Items selected', // Show the selected items count when in recreate mode
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            : Text('Food History'), // Default title when not in recreate mode

        backgroundColor: _isRecreateMode
            ? Colors.blue
            : Colors.green, // Change color when in recreate mode

        actions: [
          // Show the recreate button only when not in recreate mode
          if (!_isRecreateMode)
            IconButton(
              icon: Icon(Icons.replay), // Recreate icon
              onPressed: _toggleRecreateMode,
            ),
          // Show the check button only in recreate mode
          if (_isRecreateMode)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _selectedItems.isEmpty
                  ? null // Disable if no items selected
                  : () {
                      _foodItems.then((foodItems) {
                        _onRecreateSelected(
                          _selectedItems
                              .map((index) =>
                                  foodItems[index]) // Get selected items
                              .toList(),
                        );
                      });
                    },
            ),
        ],
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

          // List of food items to display
          List<FoodHistory> foodItems = snapshot.data!;
          return ListView.builder(
            itemCount: foodItems.length,
            itemBuilder: (context, index) {
              final foodItem = foodItems[index];

              // Format the expiry date
              final formattedExpiryDate = DateFormat('dd MMM yyyy')
                  .format(foodItem.expiryDate.toDate());

              // Icon based on status
              Icon statusIcon;
              Color iconColor;

              switch (foodItem.status) {
                case 'consumed':
                  statusIcon = Icon(Icons.check_circle, color: Colors.green);
                  iconColor = Colors.green;
                  break;
                case 'discarded':
                  statusIcon = Icon(Icons.delete, color: Colors.red);
                  iconColor = Colors.red;
                  break;
                default:
                  statusIcon = Icon(Icons.pending, color: Colors.grey);
                  iconColor = Colors.grey;
              }

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                elevation: 5,
                child: ListTile(
                  contentPadding: EdgeInsets.all(15),
                  title: Text(
                    foodItem.productName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Expiry: ${formattedExpiryDate}\nStatus: ${foodItem.status}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: _isRecreateMode
                      ? null // Hide status icon in recreate mode
                      : statusIcon, // Show status icon if not in recreate mode
                  leading: _isRecreateMode
                      ? Checkbox(
                          value: _selectedItems.contains(index),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedItems.add(index);
                              } else {
                                _selectedItems.remove(index);
                              }
                            });
                          },
                        )
                      : null, // Show checkbox only in recreate mode
                  onTap: () {},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
