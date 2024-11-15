import 'package:flutter/material.dart';


class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String documentId;

  FoodItemCard({required this.data, required this.documentId});

  String formatDate(String date) {
    // Add your date formatting logic here
    return date; // Placeholder implementation
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.fastfood), // Replace with dynamic icon logic
        title: Text(data['productName'] ?? 'No Name'),
        subtitle: Text(
          "Quantity: ${data['quantity']}\nExpires: ${formatDate(data['expiryDate'])}",
        ),
        onTap: () {
          // Show action buttons on tap
        },
      ),
    );
  }
}
