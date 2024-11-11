import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String name;
  final DateTime expiryDate;
  final String category;
  final String userId;

  FoodItem({
    required this.name,
    required this.expiryDate,
    required this.category,
    required this.userId,
  });

  factory FoodItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      name: data['productName'] ?? '',
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      userId: data['userId'] ?? '',
    );
  }
}
