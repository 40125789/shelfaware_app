import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/food_history.dart';

void main() {
  group('FoodHistory', () {
    test('fromFirestore creates a valid FoodHistory object', () {
      final data = {
        'productName': 'Apple',
        'category': 'Fruit',
        'expiryDate': Timestamp.fromDate(DateTime(2023, 12, 31)),
        'quantity': 10,
        'status': 'Fresh',
        'storageLocation': 'Fridge',
        'notes': 'Keep refrigerated',
        'userId': 'user123',
        'addedOn': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'updatedOn': Timestamp.fromDate(DateTime(2023, 1, 2)),
      };

      final foodHistory = FoodHistory.fromFirestore(data);

      expect(foodHistory.productName, 'Apple');
      expect(foodHistory.category, 'Fruit');
      expect(
          foodHistory.expiryDate, Timestamp.fromDate(DateTime(2023, 12, 31)));
      expect(foodHistory.quantity, 10);
      expect(foodHistory.status, 'Fresh');
      expect(foodHistory.storageLocation, 'Fridge');
      expect(foodHistory.notes, 'Keep refrigerated');
      expect(foodHistory.userId, 'user123');
      expect(foodHistory.addedOn, Timestamp.fromDate(DateTime(2023, 1, 1)));
      expect(foodHistory.updatedOn, Timestamp.fromDate(DateTime(2023, 1, 2)));
    });

    test('fromFirestore handles missing fields with default values', () {
      final data = {
        'productName': 'Banana',
        'expiryDate': Timestamp.fromDate(DateTime(2023, 12, 31)),
        'quantity': 5,
        'addedOn': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'updatedOn': Timestamp.fromDate(DateTime(2023, 1, 2)),
      };

      final foodHistory = FoodHistory.fromFirestore(data);

      expect(foodHistory.productName, 'Banana');
      expect(foodHistory.category, 'All');
      expect(
          foodHistory.expiryDate, Timestamp.fromDate(DateTime(2023, 12, 31)));
      expect(foodHistory.quantity, 5);
      expect(foodHistory.status, '');
      expect(foodHistory.storageLocation, '');
      expect(foodHistory.notes, '');
      expect(foodHistory.userId, '');
      expect(foodHistory.addedOn, Timestamp.fromDate(DateTime(2023, 1, 1)));
      expect(foodHistory.updatedOn, Timestamp.fromDate(DateTime(2023, 1, 2)));
    });
  });
}
