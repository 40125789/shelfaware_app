import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/food_item_form.dart';

void main() {
  testWidgets('FoodItemForm initializes correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodItemForm(
            isRecreated: false,
            onSave: (productName, expiryDate, quantity, storageLocation, notes,
                category, productImage) {},
          ),
        ),
      ),
    );

    expect(find.text('Product Name'), findsOneWidget);
    expect(find.text('Expiry Date'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Storage Location'), findsOneWidget);
    expect(find.text('Notes (Optional)'), findsOneWidget);
    expect(find.text('Save Food Item'), findsOneWidget);
  });

  testWidgets('FoodItemForm increments and decrements quantity',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodItemForm(
            isRecreated: false,
            onSave: (productName, expiryDate, quantity, storageLocation, notes,
                category, productImage) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
