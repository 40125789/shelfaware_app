import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/utils/food_utils.dart';

void main() {

  group('FoodUtils', () {
    test('groupItemsByExpiry groups items correctly', () {
      final now = DateTime.now();

      final items = [
        // Expired item
        FakeQueryDocumentSnapshot({
          'expiryDate': Timestamp.fromDate(now.subtract(Duration(days: 1)))
        }),
        // Expiring soon item
        FakeQueryDocumentSnapshot(
            {'expiryDate': Timestamp.fromDate(now.add(Duration(days: 3)))}),
        // Fresh item
        FakeQueryDocumentSnapshot(
            {'expiryDate': Timestamp.fromDate(now.add(Duration(days: 10)))}),
      ];

      final groupedItems = FoodUtils.groupItemsByExpiry(items);

      expect(groupedItems['Expired']!.length, 1);
      expect(groupedItems['Expiring Soon']!.length, 1);
      expect(groupedItems['Fresh']!.length, 1);
    });

    test('getCategoryColor returns correct color', () {
      expect(FoodUtils.getCategoryColor('Expired'), Colors.red);
      expect(FoodUtils.getCategoryColor('Expiring Soon'), Colors.orange);
      expect(FoodUtils.getCategoryColor('Fresh'), Colors.green);
      expect(FoodUtils.getCategoryColor('Unknown'), Colors.blueAccent);
    });

    test('formatExpiryDate formats correctly', () {
      final now = DateTime.now();

      final expiredTimestamp =
          Timestamp.fromDate(now.subtract(Duration(days: 1)));
      final expiringTodayTimestamp = Timestamp.fromDate(now);
      final expiringIn3DaysTimestamp =
          Timestamp.fromDate(now.add(Duration(days: 3)));

      expect(FoodUtils.formatExpiryDate(expiredTimestamp), 'Expired');
      expect(
          FoodUtils.formatExpiryDate(expiringTodayTimestamp), 'Expires today');
      expect(FoodUtils.formatExpiryDate(expiringIn3DaysTimestamp),
          'Expires in: 3 days');
    });
  });
}
  


// ignore: subtype_of_sealed_class
/// A fake implementation of QueryDocumentSnapshot for testing purposes.
class FakeQueryDocumentSnapshot implements QueryDocumentSnapshot {
  final Map<String, dynamic> _data;

  FakeQueryDocumentSnapshot(this._data);

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

