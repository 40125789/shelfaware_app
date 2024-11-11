import 'package:flutter/material.dart';
import '../models/food_item.dart';

class ExpiringItemsTab extends StatelessWidget {
  final List<FoodItem> expiringItems;

  const ExpiringItemsTab({Key? key, required this.expiringItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (expiringItems.isEmpty) {
      return Center(child: Text('No expiring items soon.'));
    }

    return ListView.builder(
      itemCount: expiringItems.length,
      itemBuilder: (context, index) {
        final item = expiringItems[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('Expires on: ${item.expiryDate}'),
        );
      },
    );
  }
}
