import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/consumed_dialog.dart';

void main() {
  testWidgets('ConsumedDialog displays correctly', (WidgetTester tester) async {
    int submittedQuantity = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsumedDialog(
            maxQuantity: 5,
            onSubmit: (quantity) {
              submittedQuantity = quantity;
            },
          ),
        ),
      ),
    );

    expect(find.text('Consumed Quantity'), findsOneWidget);
    expect(find.byType(DropdownButton<int>), findsOneWidget);
    expect(find.byType(TextButton), findsNWidgets(2));
  });

  testWidgets('ConsumedDialog submits selected quantity',
      (WidgetTester tester) async {
    int submittedQuantity = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsumedDialog(
            maxQuantity: 5,
            onSubmit: (quantity) {
              submittedQuantity = quantity;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(submittedQuantity, 3);
  });

  testWidgets('ConsumedDialog cancels without submitting',
      (WidgetTester tester) async {
    int submittedQuantity = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsumedDialog(
            maxQuantity: 5,
            onSubmit: (quantity) {
              submittedQuantity = quantity;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(submittedQuantity, 0);
  });

  testWidgets('ConsumedDialog updates selected quantity',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsumedDialog(
            maxQuantity: 5,
            onSubmit: (quantity) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
  });
}
