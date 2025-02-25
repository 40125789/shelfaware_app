import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/food_item_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  testWidgets('FoodItemCard displays correct data', (WidgetTester tester) async {
    final data = {
      'productName': 'Apple',
      'quantity': 5, // Ensure it's an int
      'expiryDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
      'category': 'fruit',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodItemCard(
            data: data,
            documentId: 'testDocId',
            onEdit: (id) {},
            onDelete: (id) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(); // Ensure UI updates

    expect(find.text('Apple'), findsOneWidget);


    // Flexible text matching for quantity
    expect(find.byWidgetPredicate((widget) =>
        widget is Text && widget.data?.contains('Quantity') == true), findsOneWidget);
    expect(find.byWidgetPredicate((widget) =>
        widget is Text && widget.data?.contains('5') == true), findsOneWidget);
    
    expect(find.textContaining('Expires in'), findsOneWidget);
  });

  testWidgets('FoodItemCard calls onEdit when edit is selected',
      (WidgetTester tester) async {
    final data = {
      'productName': 'Apple',
      'quantity': 5,
      'expiryDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
      'category': 'fruit',
    };

    String? editedDocumentId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodItemCard(
            data: data,
            documentId: 'testDocId',
            onEdit: (id) {
              editedDocumentId = id;
            },
            onDelete: (id) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(editedDocumentId, 'testDocId');
  });

  testWidgets('FoodItemCard calls onDelete when delete is selected',
      (WidgetTester tester) async {
    final data = {
      'productName': 'Apple',
      'quantity': 5,
      'expiryDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
      'category': 'fruit',
    };

    String? deletedDocumentId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodItemCard(
            data: data,
            documentId: 'testDocId',
            onEdit: (id) {},
            onDelete: (id) {
              deletedDocumentId = id;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deletedDocumentId, 'testDocId');
  });
}
