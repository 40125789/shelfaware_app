import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/food_category.dart';
import 'package:shelfaware_app/models/food_category_icons.dart'; // Assuming you're using Firestore

class FoodItemList extends StatefulWidget {
  final List<QueryDocumentSnapshot> filteredItems; // Assuming you're passing the filtered list

  FoodItemList({required this.filteredItems});

  @override
  _FoodItemListState createState() => _FoodItemListState();
}

class _FoodItemListState extends State<FoodItemList> {
  // Map to store whether each category is expanded or not
  final Map<String, bool> _expandedCategories = {
    'Expired': false,
    'Expiring Soon': false,
    'Fresh': false,
  };

  // Group food items by expiry status
  Map<String, List<QueryDocumentSnapshot>> _groupFoodItems() {
    DateTime now = DateTime.now();
    Map<String, List<QueryDocumentSnapshot>> groupedItems = {
      'Expired': [],
      'Expiring Soon': [],
      'Fresh': [],
    };

    for (var document in widget.filteredItems) {
      final data = document.data() as Map<String, dynamic>;
      final expiryTimestamp = data['expiryDate'] as Timestamp;
      DateTime expiryDate = expiryTimestamp.toDate();
      
      // Group based on expiry date
      if (expiryDate.isBefore(now)) {
        groupedItems['Expired']?.add(document);
      } else if (expiryDate.isAfter(now) && expiryDate.isBefore(now.add(Duration(days: 3)))) {
        groupedItems['Expiring Soon']?.add(document);
      } else {
        groupedItems['Fresh']?.add(document);
      }
    }
    
    return groupedItems;
  }

  // Method to toggle expand/collapse state for a category
  void _toggleExpansion(String category) {
    setState(() {
      _expandedCategories[category] = !_expandedCategories[category]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<QueryDocumentSnapshot>> groupedItems = _groupFoodItems();

    return ListView(
      children: [
        // Display "Expired" category
        CategoryHeaderWidget(
          title: 'Expired',
          foodItems: groupedItems['Expired']!,
          isExpanded: _expandedCategories['Expired']!,
          onToggle: () => _toggleExpansion('Expired'),
        ),
        
        // Display "Expiring Soon" category
        CategoryHeaderWidget(
          title: 'Expiring Soon',
          foodItems: groupedItems['Expiring Soon']!,
          isExpanded: _expandedCategories['Expiring Soon']!,
          onToggle: () => _toggleExpansion('Expiring Soon'),
        ),
        
        // Display "Fresh" category
        CategoryHeaderWidget(
          title: 'Fresh',
          foodItems: groupedItems['Fresh']!,
          isExpanded: _expandedCategories['Fresh']!,
          onToggle: () => _toggleExpansion('Fresh'),
        ),
      ],
    );
  }
}

// Category Header Widget
class CategoryHeaderWidget extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot> foodItems;
  final bool isExpanded;
  final VoidCallback onToggle;

  CategoryHeaderWidget({
    required this.title,
    required this.foodItems,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text('$title (${foodItems.length})'),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: onToggle, // Toggle the expansion state when tapped
          ),
        ),
        // Display food items only if the category is expanded
        if (isExpanded)
          Column(
            children: foodItems.map((document) {
              return FoodItemCard(document: document);
            }).toList(),
          ),
      ],
    );
  }
}

// Food Item Card Widget
class FoodItemCard extends StatelessWidget {
  final QueryDocumentSnapshot document;

  FoodItemCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final data = document.data() as Map<String, dynamic>;
    final expiryTimestamp = data['expiryDate'] as Timestamp;

    String? fetchedFoodType = data['category'];
    FoodCategory foodCategory;

    if (fetchedFoodType != null) {
      foodCategory = FoodCategory.values.firstWhere(
        (e) => e.toString().split('.').last == fetchedFoodType,
        orElse: () => FoodCategory.values.first,
      );
    } else {
      foodCategory = FoodCategory.values.first;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Icon(FoodCategoryIcons.getIcon(foodCategory)),
        ),
        title: Text(
          data['productName'] ?? 'No Name',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Quantity: ${data['quantity']}\n${_formatExpiryDate(expiryTimestamp)}",
        ),
      ),
    );
  }

  // Helper method to format expiry date
  String _formatExpiryDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }
}
