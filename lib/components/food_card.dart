import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/components/expiry_icon.dart';
import 'package:shelfaware_app/models/food_category.dart';
import 'package:shelfaware_app/models/food_category_icons.dart';
import 'package:shelfaware_app/utils/food_utils.dart';

class FoodCard extends StatelessWidget {
  final QueryDocumentSnapshot document;
  final Function(BuildContext, String) onTap;
  final Function(String) onEdit;
  final Function(String) onDelete;
  final Function(String) onDonate;
  final Function(String) onAddToShoppingList;

  const FoodCard({
    Key? key,
    required this.document,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onDonate,
    required this.onAddToShoppingList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = document.data() as Map<String, dynamic>;
    final expiryTimestamp = data['expiryDate'] as Timestamp;
    String documentId = document.id;

    return InkWell(
      onTap: () => onTap(context, documentId),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          leading: _buildCategoryIcon(data),
          title: Text(
            data['productName'] ?? 'No Name',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "Quantity: ${data['quantity']}\n${FoodUtils.formatExpiryDate(expiryTimestamp)}",
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: ExpiryIcon(expiryTimestamp: expiryTimestamp),
              ),
              _buildPopupMenu(context, documentId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(Map<String, dynamic> data) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Icon(FoodCategoryIcons.getIcon(
          FoodCategory.values.firstWhere(
        (e) =>
            e.toString().split('.').last == data['category'],
        orElse: () => FoodCategory.values.first,
      ))),
    );
  }

  Widget _buildPopupMenu(BuildContext context, String documentId) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (String value) {
        switch (value) {
          case 'edit':
            onEdit(documentId);
            break;
          case 'delete':
            onDelete(documentId);
            break;
          case 'donate':
            onDonate(documentId);
            break;
          case 'Add to Shopping List':
            onAddToShoppingList(documentId);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        _buildMenuItem('edit', Icons.edit, 'Edit'),
        _buildMenuItem('delete', Icons.delete, 'Delete'),
        _buildMenuItem('donate', Icons.volunteer_activism, 'Donate'),
        _buildMenuItem('Add to Shopping List', Icons.shopping_cart, '+ Shopping List'),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}