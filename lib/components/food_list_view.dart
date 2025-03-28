import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/components/food_item_form.dart';
import 'package:shelfaware_app/components/mark_food_dialogue.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';
import 'package:shelfaware_app/services/shopping_list_service.dart';
import 'package:shelfaware_app/components/empty_food_list.dart';
import 'package:shelfaware_app/components/food_category_tile.dart';
import 'package:shelfaware_app/utils/food_dialog_utils.dart';
import 'package:shelfaware_app/utils/food_utils.dart';

class FoodListView extends StatelessWidget {
  final User user;
  final String selectedFilter;
  final DonationService donationService;
  final FoodService foodService = FoodService();
  final ShoppingListService shoppingListService = ShoppingListService();

  FoodListView({
    required this.user,
    required this.selectedFilter,
    required this.donationService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foodItems')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching food items'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyFoodList();
        }

        final filteredItems = _filterItems(snapshot.data!.docs);

        if (filteredItems.isEmpty) {
          return const Center(
              child: Text('No food items match the selected filter.'));
        }

        final groupedItems = FoodUtils.groupItemsByExpiry(filteredItems);

        return _buildFoodList(context, groupedItems);
      },
    );
  }

  List<QueryDocumentSnapshot> _filterItems(List<QueryDocumentSnapshot> docs) {
    return selectedFilter == 'All'
        ? docs
        : docs.where((doc) => doc['category'] == selectedFilter).toList();
  }

  Widget _buildFoodList(BuildContext context,
      Map<String, List<QueryDocumentSnapshot>> groupedItems) {
    return ListView(
      children: groupedItems.keys.map((category) {
        return FoodCategoryTile(
          category: category,
          items: groupedItems[category]!,
          onItemTap: _showMarkFoodDialog,
          onItemEdit: (documentId) => _editFoodItem(context, documentId),
          onItemDelete: (documentId) => _deleteFoodItem(context, documentId),
          onItemDonate: (documentId) => _confirmDonation(context, documentId),
          onItemAddToShoppingList: (documentId) =>
              _addToShoppingList(context, documentId),
        );
      }).toList(),
    );
  }

  void _showMarkFoodDialog(BuildContext context, String documentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return MarkFoodDialog(documentId: documentId);
      },
    );
  }

  void _editFoodItem(BuildContext context, String documentId) async {
    final foodItemData = await foodService.fetchFoodItemById(documentId);

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
                    notes, category, productImage) async {
                  await foodService.updateFoodItem(documentId, {
                    'productName': productName,
                    'expiryDate': expiryDate,
                    'quantity': quantity,
                    'storageLocation': storageLocation,
                    'notes': notes,
                    'category': category,
                    'productImage': productImage,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Food Item updated successfully!")),
                  );
                },
                foodItems: [],
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteFoodItem(BuildContext context, String documentId) async {
    bool? confirm = await DialogUtils.showConfirmDialog(
      context: context,
      title: "Confirm Deletion",
      content:
          "Are you sure you want to delete this item? This action cannot be undone.",
      cancelButtonText: "Cancel",
      confirmButtonText: "Delete",
    );

    if (confirm == true) {
      try {
        await foodService.deleteFoodItem(documentId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Item deleted successfully.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete item: $e")),
        );
      }
    }
  }

  Future<void> _confirmDonation(BuildContext context, String documentId) async {
    bool? confirm = await DialogUtils.showConfirmDialog(
      context: context,
      title: "Confirm Donation",
      content: "Are you sure you want to donate this item?",
      cancelButtonText: "Cancel",
      confirmButtonText: "Donate",
    );

    if (confirm == true) {
      await _donateFoodItem(context, documentId);
    }
  }

  Future<void> _donateFoodItem(BuildContext context, String documentId) async {
    try {
      Position userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await donationService.donateFoodItem(context, documentId, userPosition);
    } catch (e) {
      print('Error donating food item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to donate item: $e")),
      );
    }
  }

  Future<void> _addToShoppingList(
      BuildContext context, String documentId) async {
    try {
      final foodItemData = await foodService.fetchFoodItemById(documentId);
      if (foodItemData != null) {
        final productName = foodItemData['productName'] ?? 'Unnamed Item';

        await shoppingListService.addToShoppingList(productName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'$productName' added to shopping list")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not find item details")),
        );
      }
    } catch (e) {
      print('Error adding to shopping list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add item to shopping list")),
      );
    }
  }
}
