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
  List<int> _selectedItems = [];
  bool _isRecreateMode = false;
  bool _isGrouped = false; // For grouping by consumed and discarded
  bool _isNewestToOldest = true; // For sorting by newest to oldest

  @override
  void initState() {
    super.initState();
    _foodItems = HistoryService().getHistoryItems(widget.userId);
  }

  void _onRecreateSelected(List<FoodHistory> selectedFoodItems) {
    if (selectedFoodItems.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddFoodItem(
            foodItem: selectedFoodItems.first,
            isRecreated: true,
            foodItems: selectedFoodItems,
           
          ),
        ),
      ).then((_) {
        if (selectedFoodItems.length > 1) {
          _onRecreateSelected(selectedFoodItems.sublist(1));
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one food item to recreate.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleRecreateMode() {
    setState(() {
      _isRecreateMode = !_isRecreateMode;
      if (!_isRecreateMode) {
        _selectedItems.clear();
      }
    });
  }

  void _sortFoodItems(List<FoodHistory> foodItems) {
    if (_isGrouped) {
      foodItems.sort((a, b) {
        if (a.status == b.status) {
          return a.updatedOn.compareTo(b.updatedOn);
        }
        return a.status == 'consumed' ? -1 : 1;
      });
    } else {
      foodItems.sort((a, b) {
        return _isNewestToOldest
            ? b.updatedOn.compareTo(a.updatedOn) // Newest to Oldest
            : a.updatedOn.compareTo(b.updatedOn); // Oldest to Newest
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: !_isRecreateMode
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isRecreateMode = false; // Exit recreate mode
                    _selectedItems.clear(); // Clear selected items
                  });
                },
              ), // No back arrow in recreate mode, or it will exit recreate mode
        title: Text(
          _isRecreateMode
              ? '${_selectedItems.length} Items selected'
              : 'Food History',
        ),
        backgroundColor: _isRecreateMode ? Colors.blue : Colors.green,
        actions: [
          if (!_isRecreateMode)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _toggleRecreateMode,
            ),
          if (_isRecreateMode)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _selectedItems.isEmpty
                  ? null
                  : () {
                      _foodItems.then((foodItems) {
                        _onRecreateSelected(
                          _selectedItems
                              .map((index) => foodItems[index])
                              .toList(),
                        );
                      });
                    },
            ),
        ],
      ),
      body: Column(
        children: [
          // Dropdown for sorting options below the app bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _isGrouped
                  ? 'Group by Status'
                  : _isNewestToOldest
                      ? 'Newest First'
                      : 'Oldest First',
              items: [
                DropdownMenuItem<String>(
                  value: 'Group by Status',
                  child: Text('Group by Status'),
                ),
                DropdownMenuItem<String>(
                  value: 'Newest First',
                  child: Text('Sort by Newest'),
                ),
                DropdownMenuItem<String>(
                  value: 'Oldest First',
                  child: Text('Sort by Oldest'),
                ),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  if (newValue == 'Group by Status') {
                    _isGrouped = true;
                    _isNewestToOldest =
                        false; // Reset to disable "Newest First"
                  } else if (newValue == 'Newest First') {
                    _isNewestToOldest = true;
                    _isGrouped = false; // Reset to disable "Group by Status"
                  } else if (newValue == 'Oldest First') {
                    _isNewestToOldest = false;
                    _isGrouped = false; // Reset to disable "Group by Status"
                  }

                  // Reload the food items after applying sorting/filtering
                  _foodItems = HistoryService().getHistoryItems(widget.userId);
                });
              },
            ),
          ),
          // Food list
          Expanded(
            child: FutureBuilder<List<FoodHistory>>(
              future: _foodItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No food items found.'));
                }

                List<FoodHistory> foodItems = snapshot.data!;

                // Sort the food items based on the current state
                _sortFoodItems(foodItems);

                return ListView.builder(
                  itemCount: foodItems.length,
                  itemBuilder: (context, index) {
                    final foodItem = foodItems[index];
                    final formattedDate = DateFormat('dd MMM yyyy')
                        .format(foodItem.updatedOn.toDate());
                    String statusText = foodItem.status == 'consumed'
                        ? 'Consumed'
                        : 'Discarded';
                    Color textColor = foodItem.status == 'consumed'
                        ? Colors.green
                        : Colors.red;
                    Color borderColor = foodItem.status == 'consumed'
                        ? Colors.green
                        : Colors.red;

                    IconData statusIcon = foodItem.status == 'consumed'
                        ? Icons.check
                        : Icons.delete;

                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: borderColor, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(15),
                        title: Text(
                          foodItem.productName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              statusText, // Only status text is colored
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' on $formattedDate', // Date in grey and not bold
                              style: TextStyle(
                                color: Colors.grey, // Grey color for the date
                                fontWeight: FontWeight.normal, // Not bold
                              ),
                            ),
                            Spacer(),
                            Icon(
                              statusIcon,
                              color: textColor,
                            ),
                          ],
                        ),
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
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
