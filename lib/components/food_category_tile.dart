import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/components/food_card.dart';
import 'package:shelfaware_app/utils/food_utils.dart';

class FoodCategoryTile extends StatelessWidget {
  final String category;
  final List<QueryDocumentSnapshot> items;
  final Function(BuildContext, String) onItemTap;
  final Function(String) onItemEdit;
  final Function(String) onItemDelete;
  final Function(String) onItemDonate;
  final Function(String) onItemAddToShoppingList;

  const FoodCategoryTile({
    Key? key,
    required this.category,
    required this.items,
    required this.onItemTap,
    required this.onItemEdit,
    required this.onItemDelete,
    required this.onItemDonate,
    required this.onItemAddToShoppingList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int itemCount = items.length;
    Color categoryColor = FoodUtils.getCategoryColor(category);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: categoryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '($itemCount items)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      children: items
          .map((document) => FoodCard(
                document: document,
                onTap: onItemTap,
                onEdit: onItemEdit,
                onDelete: onItemDelete,
                onDonate: onItemDonate,
                onAddToShoppingList: onItemAddToShoppingList,
              ))
          .toList(),
    );
  }
}
