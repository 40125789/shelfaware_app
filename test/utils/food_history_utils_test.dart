import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/models/food_history.dart';
import 'package:shelfaware_app/utils/food_history_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('FoodHistoryUtils Tests', () {
    List<FoodHistory> foodItems = [];

    setUp(() {
      foodItems = [
        FoodHistory(
          status: 'consumed',
          updatedOn: Timestamp.fromDate(DateTime(2023, 10, 1)),
          productName: 'Apple',
          category: 'Fruit',
          expiryDate: Timestamp.fromDate(DateTime(2023, 10, 10)),
          quantity: 1,
          storageLocation: 'Fridge',
          notes: 'Fresh',
          userId: 'user123',
          addedOn: Timestamp.fromDate(DateTime(2023, 9, 25)),
        ),
        FoodHistory(
          status: 'discarded',
          updatedOn: Timestamp.fromDate(DateTime(2023, 9, 1)),
          productName: 'Banana',
          category: 'Fruit',
          expiryDate: Timestamp.fromDate(DateTime(2023, 9, 10)),
          quantity: 2,
          storageLocation: 'Fridge',
          notes: 'Overripe',
          userId: 'user123',
          addedOn: Timestamp.fromDate(DateTime(2023, 8, 25)),
        ),
        FoodHistory(
          status: 'consumed',
          updatedOn: Timestamp.fromDate(DateTime(2023, 8, 1)),
          productName: 'Carrot',
          category: 'Vegetable',
          expiryDate: Timestamp.fromDate(DateTime(2023, 8, 10)),
          quantity: 5,
          storageLocation: 'Pantry',
          notes: 'Fresh',
          userId: 'user123',
          addedOn: Timestamp.fromDate(DateTime(2023, 7, 25)),
        ),
      ];
    });

    test('sortFoodHistoryItems sorts items from newest to oldest', () {
      sortFoodHistoryItems(foodItems, true);
      expect(foodItems[0].updatedOn.toDate(), DateTime(2023, 10, 1));
      expect(foodItems[1].updatedOn.toDate(), DateTime(2023, 9, 1));
      expect(foodItems[2].updatedOn.toDate(), DateTime(2023, 8, 1));
    });

    test('sortFoodHistoryItems sorts items from oldest to newest', () {
      sortFoodHistoryItems(foodItems, false);
      expect(foodItems[0].updatedOn.toDate(), DateTime(2023, 8, 1));
      expect(foodItems[1].updatedOn.toDate(), DateTime(2023, 9, 1));
      expect(foodItems[2].updatedOn.toDate(), DateTime(2023, 10, 1));
    });

    test('filterFoodHistoryItems filters consumed items', () {
      List<FoodHistory> filteredItems =
          filterFoodHistoryItems(foodItems, 'Show Consumed');
      expect(filteredItems.length, 2);
      expect(filteredItems.every((item) => item.status == 'consumed'), true);
    });

    test('filterFoodHistoryItems filters discarded items', () {
      List<FoodHistory> filteredItems =
          filterFoodHistoryItems(foodItems, 'Show Discarded');
      expect(filteredItems.length, 1);
      expect(filteredItems.every((item) => item.status == 'discarded'), true);
    });

    test('filterFoodHistoryItems returns all items when no filter is applied',
        () {
      List<FoodHistory> filteredItems =
          filterFoodHistoryItems(foodItems, 'Show All');
      expect(filteredItems.length, 3);
    });

    test('groupFoodHistoryItemsByMonth groups items by month and year', () {
      Map<String, List<FoodHistory>> groupedItems =
          groupFoodHistoryItemsByMonth(foodItems);
      expect(groupedItems.length, 3);
      expect(groupedItems['October 2023']!.length, 1);
      expect(groupedItems['September 2023']!.length, 1);
      expect(groupedItems['August 2023']!.length, 1);
    });
  });
}
