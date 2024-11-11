import 'package:flutter/material.dart';
import '../models/food_item.dart';

class ExpiredItemsTab extends StatelessWidget {
  final List<FoodItem> expiredItems;

  const ExpiredItemsTab({Key? key, required this.expiredItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (expiredItems.isEmpty) {
      return Center(child: Text('No expired items.'));
    }

    return ListView.builder(
      itemCount: expiredItems.length,
      itemBuilder: (context, index) {
        final item = expiredItems[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('Expired on: ${item.expiryDate}'),
        );
      },
    );
  }
}
