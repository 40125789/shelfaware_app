import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/food_history.dart';
import 'package:shelfaware_app/components/food_item_form.dart';
import 'package:shelfaware_app/services/food_service.dart';

class AddFoodItem extends StatefulWidget {
   final List<dynamic> foodItems;
  final FoodHistory? foodItem;
  final String? productImage;
  final bool isRecreated;

  AddFoodItem({
    Key? key,
    this.foodItem,
    this.isRecreated = false,
    required this.foodItems,
  
    this.productImage,
  }) : super(key: key);

  @override
  _AddFoodItemState createState() => _AddFoodItemState();
}

class _AddFoodItemState extends State<AddFoodItem> {
  final FoodService _foodItemService = FoodService();

  Future<void> _saveFoodItem(
    String productName,
    DateTime expiryDate,
    int quantity,
    String storageLocation,
    String notes,
    String category,
    String? productImage,
  ) async {
    // Display loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await _foodItemService.saveFoodItem(
        productName: productName,
        expiryDate: expiryDate,
        quantity: quantity,
        storageLocation: storageLocation,
        notes: notes,
        category: category,
        productImage: productImage,
      );

      // Close the loading indicator
      Navigator.pop(context);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food item saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to the previous screen
      Navigator.pop(context);
    } catch (e) {
      // Close the loading indicator
      Navigator.pop(context);

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save food item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food Item'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: FoodItemForm(
              foodItem: widget.foodItem,
              isRecreated: widget.isRecreated,
              productImage: widget.productImage,
              onSave: _saveFoodItem, foodItems: [],
            ),
          ),
        ),
      ),
    );
  }
}