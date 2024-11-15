import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/filter_dropdown.dart';
import 'package:shelfaware_app/components/food_card_widget.dart';

class InventoryPage extends StatelessWidget {
  final String selectedFilter;
  final List<String> filterOptions;
  final ValueChanged<String?> onFilterChanged;

  InventoryPage({
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Column(
      children: [
        FilterDropdown(
          selectedFilter: selectedFilter,
          filterOptions: filterOptions,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                return const Center(child: Text('No food items found'));
              }

              final filteredItems = selectedFilter == 'All'
                  ? snapshot.data!.docs
                  : snapshot.data!.docs
                      .where((doc) => doc['category'] == selectedFilter)
                      .toList();

              return ListView(
                children: filteredItems.map((document) {
                  final data = document.data() as Map<String, dynamic>;
                  return FoodItemCard(
                    data: data,
                    documentId: document.id,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
