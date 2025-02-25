import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/components/food_item_card.dart';
import 'package:shelfaware_app/components/food_item_form.dart';
import 'package:shelfaware_app/notifiers/food_item_notifier.dart';

class FoodItemsBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String userId;
  final DateTime selectedDate; // Add selected date

  FoodItemsBottomSheet({
    required this.items,
    required this.userId,
    required this.selectedDate, // Pass selected date
  });

  @override
  _FoodItemsBottomSheetState createState() => _FoodItemsBottomSheetState();
}

class _FoodItemsBottomSheetState extends State<FoodItemsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final foodItems =
            ref.watch(foodItemProvider); // Watch the provider for updates

        // Filter the food items based on the selected date
        final filteredFoodItems = foodItems.where((item) {
          final expiryDate = item['expiryDate'] as Timestamp?;
          if (expiryDate != null) {
            final itemDate = expiryDate.toDate();
            return itemDate.year == widget.selectedDate.year &&
                itemDate.month == widget.selectedDate.month &&
                itemDate.day == widget.selectedDate.day; // Compare the dates
          }
          return false;
        }).toList();

        return Container(
          padding: EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Food Items Expiring',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: filteredFoodItems.isEmpty
                    ? Center(
                        child: Text(
                          'No food items expiring on this date',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            filteredFoodItems.length, // Use the filtered list
                        itemBuilder: (context, index) {
                          final item = filteredFoodItems[index];
                          final documentId = item['documentId'] as String?;

                          if (documentId == null) {
                            return Container(); // Skip items without a documentId
                          }

                          return FoodItemCard(
                            data: item,
                            documentId: documentId,
                            onEdit: (id) => _editFoodItem(context, id, ref),
                            onDelete: (id) => _deleteFoodItem(context, id, ref),
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

  void _editFoodItem(
      BuildContext context, String documentId, WidgetRef ref) async {
    final foodItemDoc = await FirebaseFirestore.instance
        .collection('foodItems')
        .doc(documentId)
        .get();
    final foodItemData = foodItemDoc.data();

    if (foodItemData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text('Edit Food Item')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: FoodItemForm(
                isRecreated: false,
                foodItem: foodItemData,
                productImage: foodItemData['productImage'],
                onSave: (productName, expiryDate, quantity, storageLocation,
                    notes, category, productImage) {
                  final updatedData = {
                    'productName': productName,
                    'expiryDate': expiryDate,
                    'quantity': quantity,
                    'storageLocation': storageLocation,
                    'notes': notes,
                    'category': category,
                    'productImage': productImage,
                    'userId': widget.userId,
                  };
                  ref
                      .read(foodItemProvider.notifier)
                      .updateFoodItem(documentId, updatedData);
                  Navigator.pop(context);
                  ref
                      .read(foodItemProvider.notifier)
                      .fetchFoodItems(widget.userId); // Refresh the state
                }, foodItems: [],
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteFoodItem(
      BuildContext context, String documentId, WidgetRef ref) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text(
              "Are you sure you want to delete this item? This action cannot be undone."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      ref
          .read(foodItemProvider.notifier)
          .deleteFoodItem(documentId, widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item deleted successfully.")),
      );
      ref
          .read(foodItemProvider.notifier)
          .fetchFoodItems(widget.userId); // Refresh the state
    }
  }
}
