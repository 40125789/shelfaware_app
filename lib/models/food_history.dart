import 'package:cloud_firestore/cloud_firestore.dart';

class FoodHistory {
  final String productName;
  final String category;
  final Timestamp expiryDate;
  final int quantity;
  final String status;
  final String storageLocation;
  final String notes;
  final String userId;
  final Timestamp addedOn;
  final Timestamp updatedOn;

  FoodHistory({
    required this.productName,
    required this.category,
    required this.expiryDate,
    required this.quantity,
    required this.status,
    required this.storageLocation,
    required this.notes,
    required this.userId,
    required this.addedOn,
    required this.updatedOn,
  });

  // Factory method to create FoodItem from Firestore document
  factory FoodHistory.fromFirestore(Map<String, dynamic> data) {
    return FoodHistory(
      productName: data['productName'] ?? '',
      category: data['category'] ?? 'All',
      expiryDate: data['expiryDate'],
      quantity: data['quantity'] ?? 0,
      status: data['status'] ?? '',
      storageLocation: data['storageLocation'] ?? '',
      notes: data['notes'] ?? '',
      userId: data['userId'] ?? '',
      addedOn: data['addedOn'],
      updatedOn: data['updatedOn'],
    );
  }
}
