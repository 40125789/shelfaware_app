import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shelfaware_app/models/food_category.dart';
import 'package:shelfaware_app/models/food_category_icons.dart';
import 'package:shelfaware_app/components/expiry_icon.dart';
import 'package:shelfaware_app/components/mark_food_dialogue.dart';
import 'package:shelfaware_app/services/dialog_service.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';
import 'package:shelfaware_app/utils/expiry_date_utils.dart';

class FoodListView extends StatelessWidget {
  final User user;
  final String selectedFilter;
  final DonationService donationService;

  FoodListView(
      {required this.user,
      required this.selectedFilter,
      required this.donationService});

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
          return const Center(child: Text('No food items found'));
        }

        final filteredItems = selectedFilter == 'All'
            ? snapshot.data!.docs
            : snapshot.data!.docs.where((doc) {
                return doc['category'] == selectedFilter;
              }).toList();

        if (filteredItems.isEmpty) {
          return const Center(
              child: Text('No food items match the selected filter.'));
        }

        final groupedItems = _groupItemsByExpiry(filteredItems);

        return ListView(
          children: groupedItems.keys.map((category) {
            int itemCount = groupedItems[category]!.length;
            Color categoryColor = _getCategoryColor(category);

            return ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                      '($itemCount)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              children: groupedItems[category]!.map((document) {
                final data = document.data() as Map<String, dynamic>;
                final expiryTimestamp = data['expiryDate'] as Timestamp;
                String documentId = document.id;

                return InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: MarkFoodDialog(documentId: documentId),
                        );
                      },
                    );
                  },
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
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(FoodCategoryIcons.getIcon(
                            FoodCategory.values.firstWhere(
                          (e) =>
                              e.toString().split('.').last == data['category'],
                          orElse: () => FoodCategory.values.first,
                        ))),
                      ),
                      title: Text(
                        data['productName'] ?? 'No Name',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Quantity: ${data['quantity']}\n${formatExpiryDate(expiryTimestamp)}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: ExpiryIcon(expiryTimestamp: expiryTimestamp),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert),
                            onSelected: (String value) {
                              if (value == 'edit') {
                                _editFoodItem(documentId);
                              } else if (value == 'delete') {
                                _deleteFoodItem(context, documentId);
                              } else if (value == 'donate') {
                                _confirmDonation(context, documentId);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'donate',
                                child: Row(
                                  children: [
                                    Icon(Icons.volunteer_activism),
                                    SizedBox(width: 8),
                                    Text('Donate'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        );
      },
    );
  }

  Map<String, List<QueryDocumentSnapshot>> _groupItemsByExpiry(
      List<QueryDocumentSnapshot> items) {
    final groupedItems = <String, List<QueryDocumentSnapshot>>{
      'Expired': [],
      'Expiring Soon': [],
      'Fresh': []
    };

    final now = DateTime.now();

    for (var item in items) {
      final data = item.data() as Map<String, dynamic>;
      final expiryTimestamp = data['expiryDate'] as Timestamp;
      final expiryDate = expiryTimestamp.toDate();
      final difference = expiryDate.difference(now).inDays;

      if (difference < 0) {
        groupedItems['Expired']!.add(item);
      } else if (difference <= 4) {
        groupedItems['Expiring Soon']!.add(item);
      } else {
        groupedItems['Fresh']!.add(item);
      }
    }

    return groupedItems;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Expired':
        return Colors.red;
      case 'Expiring Soon':
        return Colors.orange;
      case 'Fresh':
        return Colors.green;
      default:
        return Colors.blueAccent;
    }
  }

   // Use the new utility functions for date formatting
  String formatDate(Timestamp timestamp) {
    return ExpiryDateUtils.formatDate(timestamp);
  }

  String formatExpiryDate(Timestamp expiryTimestamp) {
    return ExpiryDateUtils.formatExpiryDate(expiryTimestamp);
  }

  void _editFoodItem(String documentId) {
    // Implement edit functionality
  }

Future<void> _deleteFoodItem(BuildContext context, String documentId) async {
    bool? confirm = await DialogService.showConfirmDeletionDialog(context);

    if (confirm == true) {
      try {
        final foodService = FoodService();
        await foodService.deleteFoodItem(documentId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Item deleted successfully.")),
        );
        // Refresh the list after deletion
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete item: $e")),
        );
      }
    }
  }

  }

Future<void> _confirmDonation(BuildContext context, String documentId) async {
    bool? confirm = await DialogService.showConfirmDonationDialog(context);

    if (confirm == true) {
      await _donateFoodItem(context, documentId);
    }
  }

  Future<void> _donateFoodItem(BuildContext context, String documentId) async {
    try {
      Position userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await DonationService.donateFoodItem(context, documentId, userPosition);
     
    } catch (e) {
      print('Error donating food item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to donate item: $e")),
      );
    }
  }

