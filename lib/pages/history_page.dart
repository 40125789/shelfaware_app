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
  bool _isNewestToOldest = true;
  String _filterOption = 'Sort by Newest'; // Default option

  @override
  void initState() {
    super.initState();
    _foodItems = HistoryService().getFoodHistory(widget.userId);
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
    foodItems.sort((a, b) {
      return _isNewestToOldest
          ? b.updatedOn.compareTo(a.updatedOn)
          : a.updatedOn.compareTo(b.updatedOn);
    });
  }

  // Filter food items by status
  List<FoodHistory> _filterFoodItems(List<FoodHistory> foodItems) {
    if (_filterOption == 'Show Consumed') {
      return foodItems.where((item) => item.status == 'consumed').toList();
    } else if (_filterOption == 'Show Discarded') {
      return foodItems.where((item) => item.status == 'discarded').toList();
    } else {
      return foodItems; // Show all items if no specific filter is applied
    }
  }

  // Group food items by month
  Map<String, List<FoodHistory>> _groupFoodItemsByMonth(List<FoodHistory> foodItems) {
    Map<String, List<FoodHistory>> groupedItems = {};

    for (var foodItem in foodItems) {
      String monthYear = DateFormat('MMMM yyyy').format(foodItem.updatedOn.toDate());
      if (!groupedItems.containsKey(monthYear)) {
        groupedItems[monthYear] = [];
      }
      groupedItems[monthYear]!.add(foodItem);
    }

    return groupedItems;
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
                    _isRecreateMode = false;
                    _selectedItems.clear();
                  });
                },
              ),
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
          // Dropdown for sorting and filtering options below the app bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Combined dropdown for sorting and filtering options
                DropdownButton<String>(
                  isExpanded: true,
                  value: _filterOption,
                  items: [
                    DropdownMenuItem<String>(
                      value: 'Sort by Newest',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward),
                          SizedBox(width: 8),
                          Text('Sort by Newest'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Sort by Oldest',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward),
                          SizedBox(width: 8),
                          Text('Sort by Oldest'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Show Consumed',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text('Show Consumed'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Show Discarded',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 8),
                          Text('Show Discarded'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _filterOption = newValue!;
                      if (_filterOption == 'Sort by Newest') {
                        _isNewestToOldest = true;
                      } else if (_filterOption == 'Sort by Oldest') {
                        _isNewestToOldest = false;
                      }
                    });
                  },
                ),
              ],
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

                // Filter food items based on status
                foodItems = _filterFoodItems(foodItems);

                // Group food items by month
                Map<String, List<FoodHistory>> groupedFoodItems =
                    _groupFoodItemsByMonth(foodItems);

                return ListView(
                  children: groupedFoodItems.keys.map((month) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month Header with Grey Background and Centered Text
                        Container(
                          width: double.infinity,
                          color: Colors.grey[200],
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Text(
                              month,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        ...groupedFoodItems[month]!.map((foodItem) {
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: foodItem.status == 'consumed'
                                    ? Colors.green
                                    : Colors.red,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(15),
                              title: Text(
                                '${foodItem.productName} x ${foodItem.quantity}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    foodItem.status == 'consumed'
                                        ? 'Consumed'
                                        : 'Discarded',
                                    style: TextStyle(
                                      color: foodItem.status == 'consumed'
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ' on ${DateFormat('dd MMM yyyy').format(foodItem.updatedOn.toDate())}',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(
                                    foodItem.status == 'consumed'
                                        ? Icons.check
                                        : Icons.delete,
                                    color: foodItem.status == 'consumed'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ],
                              ),
                              leading: _isRecreateMode
                                  ? Checkbox(
                                      value: _selectedItems.contains(
                                          groupedFoodItems[month]!
                                              .indexOf(foodItem)),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedItems.add(
                                                groupedFoodItems[month]!
                                                    .indexOf(foodItem));
                                          } else {
                                            _selectedItems.remove(
                                                groupedFoodItems[month]!
                                                    .indexOf(foodItem));
                                          }
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
