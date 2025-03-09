import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Assuming you're using Firestore
import 'package:flutter_riverpod/flutter_riverpod.dart';

final foodItemsProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance.collection('foodItems').snapshots();
});

class FoodItemList extends ConsumerWidget {
  const FoodItemList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodItemsAsyncValue = ref.watch(foodItemsProvider);

    return foodItemsAsyncValue.when(
      data: (foodItems) {
        if (foodItems.docs.isEmpty) {
          return const Center(child: Text('No food items found'));
        }

        return Expanded(
          child: ListView.builder(
            itemCount: foodItems.docs.length,
            itemBuilder: (context, index) {
              final data = foodItems.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['productName'] ?? 'No Name'),
                subtitle: Text("Quantity: ${data['quantity']}"),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
