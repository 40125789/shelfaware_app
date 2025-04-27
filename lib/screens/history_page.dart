import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/food_history_item_card.dart';
import 'package:shelfaware_app/components/food_history_month_header.dart';
import 'package:shelfaware_app/components/food_history_sorting_dropdown.dart';
import 'package:shelfaware_app/models/food_history.dart';
import 'package:shelfaware_app/screens/add_food_item.dart';
import 'package:shelfaware_app/services/history_service.dart';
import 'package:shelfaware_app/utils/food_history_utils.dart';

class HistoryPage extends StatefulWidget {
  final String userId;

  HistoryPage({required this.userId});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<FoodHistory>> _foodItems;
  List<FoodHistory> _selectedItems = []; // Store food items instead of indices
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_isRecreateMode) {
              setState(() {
                _isRecreateMode = false;
                _selectedItems.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _isRecreateMode
              ? '${_selectedItems.length} Items selected'
              : 'Food History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
          ),
        ),
        backgroundColor: _isRecreateMode ? Colors.blue : Colors.green,
        actions: [
          if (!_isRecreateMode)
            TextButton.icon(
              onPressed: _toggleRecreateMode,
              icon: Icon(Icons.replay, color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white),
              label: Text(
                'RECREATE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
                ),
              ),
            ),
          if (_isRecreateMode)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _selectedItems.isEmpty
                ? null
                : () {
                    _onRecreateSelected(_selectedItems);
                  },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FoodHistorySortingFilteringDropdown(
              filterOption: _filterOption,
              onChanged: (String? newValue) {
                setState(() {
                  _filterOption = newValue!;
                  _isNewestToOldest = _filterOption == 'Sort by Newest';
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FoodHistory>>(
              future: _foodItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No Food History Yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your food history will appear here\nonce you start adding items.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                List<FoodHistory> foodItems = snapshot.data!;

                sortFoodHistoryItems(foodItems, _isNewestToOldest);
                foodItems = filterFoodHistoryItems(foodItems, _filterOption);

                Map<String, List<FoodHistory>> groupedFoodItems =
                    groupFoodHistoryItemsByMonth(foodItems);

                return ListView(
                  children: groupedFoodItems.keys.map((month) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FoodHistoryMonthHeader(month: month),
                        ...groupedFoodItems[month]!.map((foodItem) {
                          return FoodHistoryItemCard(
                            foodItem: foodItem,
                            isRecreateMode: _isRecreateMode,
                            isSelected: _selectedItems.contains(foodItem),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedItems.add(foodItem);
                                } else {
                                  _selectedItems.remove(foodItem);
                                }
                              });
                            },
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
