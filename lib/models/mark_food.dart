import 'package:cloud_firestore/cloud_firestore.dart';


class MarkFood {
  final String id;
  final String? productName;
  final String? productImage;
  final int quantity;
  final DateTime? expiryDate;
  final String? notes;
  final String? storageLocation;
  final DateTime? addedOn;
  final String? category;
  final String? status;
  final DateTime? updatedOn;
  final String? userId;

  MarkFood({
    required this.id,
    this.productName,
    this.productImage,
    required this.quantity,
    this.expiryDate,
    this.notes,
    this.storageLocation,
    this.addedOn,
    this.category,
    this.status,
    this.updatedOn,
    this.userId,
  });

  factory MarkFood.fromMap(Map<String, dynamic> data, String documentId) {
    return MarkFood(
      id: documentId,
      productName: data['productName'] as String?,
      productImage: data['productImage'] as String?,
      quantity: data['quantity'] as int,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
      storageLocation: data['storageLocation'] as String?,
      addedOn: (data['addedOn'] as Timestamp?)?.toDate(),
      category: data['category'] as String?,
      status: data['status'] as String?,
      updatedOn: (data['updatedOn'] as Timestamp?)?.toDate(),
      userId: data['userId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'expiryDate': expiryDate,
      'notes': notes,
      'storageLocation': storageLocation,
      'addedOn': addedOn,
      'category': category,
      'status': status,
      'updatedOn': updatedOn,
      'userId': userId,
    };
  }

  MarkFood copyWith({
    String? id,
    String? productName,
    String? productImage,
    int? quantity,
    DateTime? expiryDate,
    String? notes,
    String? storageLocation,
    DateTime? addedOn,
    String? category,
    String? status,
    DateTime? updatedOn,
    String? userId,
  }) {
    return MarkFood(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      storageLocation: storageLocation ?? this.storageLocation,
      addedOn: addedOn ?? this.addedOn,
      category: category ?? this.category,
      status: status ?? this.status,
      updatedOn: updatedOn ?? this.updatedOn,
      userId: userId ?? this.userId,
    );
  }
}