import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/food_history_item_card.dart';
import 'package:shelfaware_app/models/food_history.dart';

void main() {
  testWidgets('FoodHistoryItemCard displays correct information', (WidgetTester tester) async {
    final foodItem = FoodHistory(
      productName: 'Apple',
      quantity: 3,
      status: 'consumed',
      updatedOn: Timestamp.fromDate(DateTime.now()),
      category: 'Fruit',
      expiryDate: Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
      storageLocation: 'Fridge',
      notes: 'Keep fresh',
      userId: 'user123',
      addedOn: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodHistoryItemCard(
            foodItem: foodItem,
            isRecreateMode: false,
            isSelected: false,
            onChanged: (value) {},
          ),
        ),
      ),
    );

    final anotherFoodItem = FoodHistory(
      productName: 'Banana',
      quantity: 5,
      status: 'discarded',
      updatedOn: Timestamp.fromDate(DateTime.now()),
      category: 'Fruit',
      expiryDate: Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
      storageLocation: 'Fridge',
      notes: 'Keep fresh',
      userId: 'user123',
      addedOn: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodHistoryItemCard(
            foodItem: anotherFoodItem,
            isRecreateMode: true,
            isSelected: true,
            onChanged: (value) {},
          ),
        ),
      ),
    );

    expect(find.text('Banana x 5'), findsOneWidget);
    expect(find.text('Discarded'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.text('Banana x 5'), findsOneWidget);
    expect(find.text('Discarded'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('FoodHistoryItemCard calls onChanged when checkbox is tapped', (WidgetTester tester) async {
    final foodItem = FoodHistory(
      productName: 'Orange',
      quantity: 2,
      status: 'consumed',
      updatedOn: Timestamp.fromDate(DateTime.now()),
      category: 'Citrus',
      expiryDate: Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
      storageLocation: 'Fridge',
      notes: 'Keep fresh',
      userId: 'user123',
      addedOn: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))),
    );

    bool? checkboxValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodHistoryItemCard(
            foodItem: foodItem,
            isRecreateMode: true,
            isSelected: false,
            onChanged: (value) {
              checkboxValue = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(checkboxValue, isTrue);
  });
}