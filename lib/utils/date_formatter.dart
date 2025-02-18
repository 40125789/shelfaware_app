import 'package:cloud_firestore/cloud_firestore.dart';

String formatExpiryDate(Timestamp expiryTimestamp) {
  DateTime expiryDate = expiryTimestamp.toDate();
  return "${expiryDate.day}/${expiryDate.month}/${expiryDate.year}";
}